import DemocraticPlayer from '../build/contracts/DemocraticPlayer.json'

const drizzleOptions = {
  web3: {
    block: false,
    fallback: {
      type: 'ws',
      url: 'ws://127.0.0.1:8545'
    }
  },
  contracts: [
    DemocraticPlayer,
  ],
  events: {
  },
  polls: {
    accounts: 1500
  }
}

export default drizzleOptions;
