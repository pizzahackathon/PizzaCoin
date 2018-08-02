import Web3 from 'web3'
import PizzaCoinAbi from '../abi/PizzaCoinAbi'
// import PizzaCoinStaffAbi from '../abi/PizzaCoinStaffAbi'
// import PizzaCoinTeamAbi from '../abi/PizzaCoinTeamAbi'
// import PizzaCoinPlayerAbi from '../abi/PizzaCoinPlayerAbi'
class PizzaCoin {
  constructor () {
    // connect with web3-compatible like Metamask, Cipher, Trust wallet
    if (window.web3 === 'undefined') {
      console.error('No metamask or web3 wallet found!')
    }

    this.web3 = new Web3(window.web3.currentProvider)
    this.pizzaCoinAddr = '0xe9c5c311c9fed290fcc246c93877292d525dc528'
    this.pizzaCoinStaffAddr = '0x31B82DD3eff8DA9FFC219A19a3506a9bF8D594d9'
    this.pizzaCoinTeamAddr = '0x50f2790E368745EcA659836A685875d19fBf2019'
    this.pizzaCoinPlayerAddr = '0x0d1c4B71fD15C56eB3E2aDEe030f9Dba55129376'

    this.loadUserAddress().then(account => {
      this.account = account
    })

    this.main = new this.web3.eth.Contract(PizzaCoinAbi, this.pizzaCoinAddr)
  }

  async loadUserAddress () {
    let accoutns = await this.web3.eth.getAccounts()
    return accoutns[0]
  }

  async createTeam (creatorName, teamName) {
    console.log('Creating a new team --> "' + teamName + '" ...')

    // Create a new team
    let result = await this.main.methods.createTeam(teamName, creatorName).send({
      from: this.account,
      gas: 6500000,
      gasPrice: 10000000000
    })
    console.log('... succeeded')
    console.log(result)
  }

  // async deposit (amount) {
  //   let accounts = await this.web3.eth.getAccounts()
  //   let etherAmt = this.web3.utils.toWei(amount.toString())

  //   let options = {
  //     from: accounts[0],
  //     value: etherAmt
  //   }

  //   let balance = await this.bank.methods.deposit().send(options)
  //   return balance
  // }
}

export default PizzaCoin
