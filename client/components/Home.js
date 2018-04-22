import React, { Component } from 'react'
import { AccountData, ContractData, ContractForm } from 'drizzle-react-components';

class Home extends Component {
  render() {
    return (
      <div className="container">
        <div className="pure-g">
          <div className="pure-u-1-1">
            <h2>Active Account</h2>
            <AccountData accountIndex="0" units="ether" precision="3" />

            <br/><br/>
          </div>

          <div className="pure-u-1-1">
            <h2>DemocraticPlayer</h2>
            <p>Set Chess Contract.</p>
            <p><strong>Stored Value</strong>: <ContractData contract="DemocraticPlayer" method="chess" /></p>
            <ContractForm contract="DemocraticPlayer" method="setChessContract" labels={['Chess Contract Address']} />

            <br/><br/>
          </div>

          <div className="pure-u-1-1">
            <h2>DemocraticPlayer</h2>
            <p>Here we have a form with custom, friendly labels. Also note the token symbol will not display a loading indicator. We've suppressed it with the <code>hideIndicator</code> prop because we know this variable is constant.</p>
            <p>
              <strong>Total Supply</strong>:
              <ContractData contract="DemocraticPlayer" method="totalSupply" methodArgs={[{from: this.props.accounts[0]}]} />
            </p>
            <p><strong>My Balance</strong>:
            <ContractData contract="DemocraticPlayer" method="balanceOf" methodArgs={[this.props.accounts[0]]} />
            </p>
            <h3>Mint Tokens</h3>
            <ContractForm contract="DemocraticPlayer" method="mint" labels={['To Address', 'Amount to Mint']} />

            <br/><br/>
          </div>

          {/* <div className="pure-u-1-1">
            <h2>DemocraticPlayer</h2>
            <p>Finally this contract shows data types with additional considerations. Note in the code the strings below are converted from bytes to UTF-8 strings and the device data struct is iterated as a list.</p>
            <p><strong>String 1</strong>: <ContractData contract="DemocraticPlayer" method="string1" toUtf8 /></p>
            <p><strong>String 2</strong>: <ContractData contract="DemocraticPlayer" method="string2" toUtf8 /></p>
            <strong>Single Device Data</strong>: <ContractData contract="DemocraticPlayer" method="singleDD" />

            <br/><br/>
          </div> */}
        </div>
      </div>
    )
  }
}

export default Home;
