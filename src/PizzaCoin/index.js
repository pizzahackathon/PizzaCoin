import Web3 from 'web3'
// import PizzaCoinAbi from '../abi/PizzaCoinAbi'
import PizzaCoinAbi from '../abi/pizzaCoinAbi.json'
import PizzaCoinStaffAbi from '../abi/PizzaCoinStaffAbi'
import PizzaCoinTeamAbi from '../abi/PizzaCoinTeamAbi'
import PizzaCoinPlayerAbi from '../abi/PizzaCoinPlayerAbi'
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
    this.staff = new this.web3.eth.Contract(PizzaCoinStaffAbi, this.pizzaCoinStaffAddr)
    this.team = new this.web3.eth.Contract(PizzaCoinTeamAbi, this.pizzaCoinTeamAddr)
    this.player = new this.web3.eth.Contract(PizzaCoinPlayerAbi, this.pizzaCoinPlayerAddr)

    console.log(this.main.methods)
  }

  async loadUserAddress () {
    let accounts = await this.web3.eth.getAccounts()
    console.log('loadUserAddress >> ' + accounts[0])

    return accounts[0]
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

  async getTeamCount () {
    let teamCount = await this.team.methods.getTotalTeams().call()
    return teamCount
  }

  async getPlayerCountInTeam (teamName) {
    let playerCount = await this.team.methods.getTotalPlayersInTeam(teamName).call()
    return playerCount
  }

  // /////////////// //
  // ---- TEAM ----  //
  // /////////////// //
  async getTeamsProfile () {
    let totalTeams = await this.getTeamCount()
    console.log('totalTeams: ' + totalTeams + '\n')
    let data
    let dataTeams = []
    // this.team.methods.getTotalPlayerInTeam(teamName)

    // this.team.methods.getFirstFoundPlayerInTeam(index)
    // this.player.methods.getPlayerName(address)

    let nextStartSearchingIndex = 0
    let endOfList, teamName, totalVoted
    while (true) {
      [
        endOfList,
        nextStartSearchingIndex,
        teamName,
        totalVoted
      ] = await this.getFirstFoundTeamInfo(nextStartSearchingIndex)

      if (endOfList) {
        break
      }
      console.log('teamName: ' + teamName)
      console.log('totalVoted: ' + totalVoted + '\n')

      data = await this.getPlayersProfile(teamName)
      dataTeams.push({
        name: teamName,
        members: data
      })
      console.log('profile >> ' + JSON.stringify(data))
    }

    console.log('dataTeams >>  ' + JSON.stringify(dataTeams))

    return dataTeams
  }

  async getFirstFoundTeamInfo (startSearchingIndex) {
    // console.log('\nQuerying for the first found team winner (by the index of voters) ...');
    let tupleReturned = await this.team.methods.getFirstFoundTeamInfo(startSearchingIndex).call()
    // console.log('... succeeded');

    return [
      tupleReturned._endOfList,
      tupleReturned._nextStartSearchingIndex,
      tupleReturned._teamName,
      tupleReturned._totalVoted
    ]
  }

  async registerPlayerToTeam (registrarAddr, staffAddr, staffName) {
    console.log('\nRegistering a staff --> "' + staffAddr + '" ...')
    // Register a staff
    try {
      const res = await PizzaCoin.methods.registerPlayerToTeam(staffAddr, staffName).send({
        from: registrarAddr,
        gas: 6500000,
        gasPrice: 10000000000
      })
      console.log(res)
    } catch (error) {
      console.error(error)
    }
    console.log('... succeeded')
  }

  // ///////////////// //
  // ---- PLAYER ----  //
  // ///////////////// //
  async getPlayersProfile (teamName) {
    let playerCount = await this.getPlayerCountInTeam(teamName)
    console.log(`playerCount: ${playerCount}`)
    let teams = []
    // this.team.methods.getTotalPlayerInTeam(teamName)

    // this.team.methods.getFirstFoundPlayerInTeam(teamName, index)
    // this.player.methods.getPlayerName(address)

    let nextStartSearchingIndex = 0
    let endOfList, playerAddress
    while (true) {
      [
        endOfList,
        nextStartSearchingIndex,
        playerAddress
      ] = await this.getFirstFoundPlayer(teamName, nextStartSearchingIndex)
      console.log(`endOfList >> ${endOfList}`)
      console.log(`myAccount >> ${this.account}`)
      if (endOfList) {
        break
      }
      console.log('playerAddress >> : ' + playerAddress)
      let playerName = await this.getPlayerName(playerAddress)
      console.log(`playerName >> : ${playerName}`)
      teams.push({
        'name': playerName,
        'address': playerAddress
      })
    }
    // let staffName = await this.getStaffName(this.account)
    // console.log(`getStaffName >> ${staffName}`)
    // let isStaff = await this.isStaff(this.account)
    // console.log(`isStaff >> ${isStaff}`)
    // console.log('teams >> ' + teams)
    return teams
  }

  async getFirstFoundPlayer (teamName, playerIndex) {
    // console.log('\nQuerying for the first found team winner (by the index of voters) ...');
    let tupleReturned = await this.team.methods.getFirstFoundPlayerInTeam(teamName, playerIndex).call()
    // console.log('... succeeded');

    return [
      tupleReturned._endOfList,
      tupleReturned._nextStartSearchingIndex,
      tupleReturned._player
    ]
  }

  async getPlayerName (address) {
    // console.log('\nQuerying for the first found team winner (by the index of voters) ...');
    let name = await this.player.methods.getPlayerName(address).call()
    // console.log('... succeeded');

    return name
  }

  async registerPlayer ({playerAddr, playerName, teamName}) {
    console.log('\nRegistering a player --> "' + teamName + '" ...')
    // Register a player
    try {
      await this.main.methods.registerPlayer(playerName, teamName).send({
        from: playerAddr,
        gas: 6500000,
        gasPrice: 10000000000
      })

      console.log('... succeeded')
    } catch (error) {
      console.error(error)
    }
  }

  async kickPlayer ({kickerAddr, playerAddr, teamName}) {
    console.log('\nKicking a player --> "' + playerAddr + '" ...')
    try {
      await this.main.methods.kickPlayer(playerAddr, teamName).send({
        from: kickerAddr,
        gas: 6500000,
        gasPrice: 10000000000
      })
    } catch (error) {
      console.error(error)
    }
  }

  // ///////////////// //
  // ---- STAFF ----  //
  // ///////////////// //

  async getStaffName (address) {
    let name = await this.staff.methods.getStaffName(this.account).call()

    return name
  }
  async isStaff (address) {
    console.log(`ddd >> ${address}`)

    let isStaff = await this.staff.methods.isStaff(address).call()
    console.log(`dddIs >> ${isStaff}`)

    return isStaff
  }
}

export default PizzaCoin

// let teams = [
//   {
//     name: 'PizzaHack',
//     members: [
//       {
//         name: 'Tot',
//         address: '0xabc'
//       },
//       {
//         name: 'Byte',
//         address: '0x1122'
//       }
//     ]
//   },
//   {
//     name: 'KX',
//     members: [
//       {
//         name: 'Joy',
//         address: '0xee222'
//       },
//       {
//         name: 'Game',
//         address: '0x5566'
//       }
//     ]
//   }
// ]
