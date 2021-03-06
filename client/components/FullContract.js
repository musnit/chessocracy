import { drizzleConnect } from 'drizzle-react';
import React, { Component } from 'react';
import PropTypes from 'prop-types';

import MethodCallTracker from './MethodCallTracker';

class FullContract extends Component {
  constructor(props, context) {
    super(props);

    this.drizzleContracts = context.drizzle.contracts;
    this.drizzleContract = this.drizzleContracts[this.props.contract];
    this.abi = this.drizzleContract.abi;

    this.events = this.abi.filter(entry => entry.type === 'event');
    this.methods = this.abi.filter(entry => entry.type !== 'event');
    this.constants = this.abi.filter(entry => entry.type === 'function' && entry.constant === true && entry.inputs.length === 0);
    this.lookups = this.abi.filter(entry => entry.type === 'function' && entry.constant === true && entry.inputs.length !== 0);
    this.mutators = this.abi.filter(entry => entry.type === 'function' && entry.constant === false);

    this.loadConstants();
  }

  loadConstants = _ => {
    this.constants.forEach(method => {
      this.drizzleContract.methods[method.name].cacheCall();
    });
  }

  displayValue(value) {
    return JSON.stringify(value);
  }

  translateType(type) {
    switch(true) {
      case /^uint/.test(type):
        return 'number';
        break;
      case /^string/.test(type) || /^bytes/.test(type):
        return 'text';
        break;
      case /^bool/.test(type):
        return 'checkbox';
        break;
      default:
        return 'text';
    }
  }

  render() {
    const contract = this.props.contracts[this.props.contract];
    if(!contract.initialized) {
      return <div>
        <h2>{this.props.contract} Contract Tester</h2>
        <span>Initializing...</span>
      </div>;
    }

    //TODO: test multioutput
    //TODO: get struct in/out working

    return <span>
      <h2>{this.props.contract} Contract Tester</h2>
      <div>
        <div>Constants:</div>
        <div>
          {this.constants.map(constant => <div key={constant.name}>
            <span>{constant.name}: </span>
            <span>
              {contract[constant.name]['0x0']? this.displayValue(contract[constant.name]['0x0'].value) : 'Fetching...'}
            </span>
          </div>)}
        </div>
      </div>
      <div>
        <div>Lookups:</div>
        <div>
          {this.lookups.map(method => <MethodCallTracker key={method.name}
            ABIMethod={method}
            method={this.drizzleContract.methods[method.name]}
            contract={contract} constant={true} />)}
        </div>
      </div>
      <div>
        <div>Mutators</div>
        <div>
          {this.mutators.map(method => <MethodCallTracker key={method.name}
            ABIMethod={method} contract={contract}
            method={this.drizzleContract.methods[method.name]}
            constant={false} />)}
        </div>
      </div>
    </span>;

    // If the cache key we received earlier isn't in the store yet; the initial value is still being fetched.
    // if(!(this.dataKey in this.props.contracts[this.props.contract][this.props.method])) {
    //   return (
    //     <span>Fetching...</span>
    //   )
    // }

    // Show a loading spinner for future updates.
    var pendingSpinner = this.props.contracts[this.props.contract].synced ? '' : ' 🔄'

    // Optionally hide loading spinner (EX: ERC20 token symbol).
    if (this.props.hideIndicator) {
      pendingSpinner = ''
    }

    var displayData = this.contract[this.props.method][this.dataKey].value

    // Optionally convert to UTF8
    if (this.props.toUtf8) {
      displayData = this.context.drizzle.web3.utils.hexToUtf8(displayData)
    }

    // Optionally convert to Ascii
    if (this.props.toAscii) {
      displayData = this.context.drizzle.web3.utils.hexToAscii(displayData)
    }

    // If return value is an array
    if (typeof displayData === 'array') {
      const displayListItems = displayData.map((datum, index) => {
        <li key={index}>{datum}{pendingSpinner}</li>
      })

      return(
        <ul>
          {displayListItems}
        </ul>
      )
    }

    // If retun value is an object
    if (typeof displayData === 'object') {
      var i = 0
      const displayObjectProps = []

      Object.keys(displayData).forEach((key) => {
        if (i != key) {
          displayObjectProps.push(<li key={i}>
            <strong>{key}</strong>{pendingSpinner}<br/>
            {displayData[key]}
          </li>)
        }

        i++
      })

      return(
        <ul>
          {displayObjectProps}
        </ul>
      )
    }

    return(
      <span>{displayData}{pendingSpinner}</span>
    )
  }
}

FullContract.contextTypes = {
  drizzle: PropTypes.object
}

const mapStateToProps = state => {
  return {
    contracts: state.contracts
  }
}

export default drizzleConnect(FullContract, mapStateToProps)
