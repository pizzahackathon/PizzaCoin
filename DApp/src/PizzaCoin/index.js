import Web3 from 'web3'
// import PizzaCoinAbi from '../abi/PizzaCoinAbi'
import PizzaCoinAbi from '../abi/PizzaCoinAbi.json'
import PizzaCoinStaffAbi from '../abi/PizzaCoinStaffAbi'
import PizzaCoinTeamAbi from '../abi/PizzaCoinTeamAbi'
import PizzaCoinPlayerAbi from '../abi/PizzaCoinPlayerAbi'

import validateConnection from './validateConnection'

class PizzaCoin {
  constructor (
    network = 'rinkeby',
    ethNode = 'wss://rinkeby.infura.io/_ws',
    pizzaCoinAddr = '0x5aa5bf8f1a386f6f3cc564548890ee9a7382718d',
    pizzaCoinStaffAddr = '0xb25eE5C4d11F9D934f2642d30c99319708e615D4',
    pizzaCoinTeamAddr = '0x164d120357CAc5Cea08c201D719c7D48b2054b8e',
    pizzaCoinPlayerAddr = '0xD1571785b4309F55294EF7593276B7B5505F103A') {
    this.network = network

    // connect with web3-compatible like Metamask, Cipher, Trust wallet
    if (typeof window.web3 === 'undefined') {
      // console.error('No metamask or web3 wallet found!')
      this.web3 = new Web3(new Web3.providers.WebsocketProvider(ethNode))
    } else {
      this.web3 = new Web3(window.web3.currentProvider)
    }

    this.pizzaCoinAddr = pizzaCoinAddr
    this.pizzaCoinStaffAddr = pizzaCoinStaffAddr
    this.pizzaCoinTeamAddr = pizzaCoinTeamAddr
    this.pizzaCoinPlayerAddr = pizzaCoinPlayerAddr

    this.loadUserAddress().then(account => {
      this.account = account
    })

    this.main = new this.web3.eth.Contract(PizzaCoinAbi, this.pizzaCoinAddr)
    this.staff = new this.web3.eth.Contract(PizzaCoinStaffAbi, this.pizzaCoinStaffAddr)
    this.team = new this.web3.eth.Contract(PizzaCoinTeamAbi, this.pizzaCoinTeamAddr)
    this.player = new this.web3.eth.Contract(PizzaCoinPlayerAbi, this.pizzaCoinPlayerAddr)

    console.log(this.main.methods)
    console.log(this.staff.methods)
    console.log(this.team.methods)
    console.log(this.player.methods)
  }

  async loadUserAddress () {
    let accounts = await this.web3.eth.getAccounts()
    console.log('loadUserAddress >> ' + accounts[0])

    return accounts[0]
  }

  async getTokenBalance (playerAddr) {
    let tokenBalance
    try {
      tokenBalance = await this.main.methods.balanceOf(playerAddr).call()
      console.log('playerAddr -->' + playerAddr + ': tokenBalance = ' + tokenBalance)
    } catch (error) {
      console.error(error)
    }
    return tokenBalance
  }

  async createTeam (creatorName, teamName) {
    console.log('Creating a new team --> "' + teamName + '" ...')

    // Create a new team
    let result = await this.main.methods.createTeam(teamName, creatorName).send({
      from: this.account,
      gas: 500000,
      gasPrice: 10000000000
    })
    console.log('... succeeded')
    console.log(result)
  }

  async getTeamCount () {
    let teamCount = await this.team.methods.getTotalTeams().call()
    return teamCount
  }

  async getTeamArrayLength () {
    let teamArrayLength = await this.team.methods.getTeamArrayLength().call()
    return teamArrayLength
  }

  async getPlayerCountInTeam (teamName) {
    let playerCount = await this.team.methods.getTotalPlayersInTeam(teamName).call()
    return playerCount
  }

  // /////////////// //
  // ---- TEAM ----  //
  // /////////////// //
  async getTeamsProfile () {
    try {
      let teamArrayLength = await this.getTeamArrayLength()
      console.log('teamArrayLength: ' + teamArrayLength + '\n')
      let data
      // let nextStartSearchingIndex = 0
      // let endOfList, teamName, totalVoted

      let teamInfoTasks = []

      for (var i = 0; i < teamArrayLength; i++) {
        teamInfoTasks.push(this.getFirstFoundTeamInfo(i))
      }

      let teamInfos = await Promise.all(teamInfoTasks)

      // Remove team empty name
      teamInfos = teamInfos.filter(teamInfo => {
        let teamName = teamInfo[2]
        return teamName !== ''
      })

      console.log(`teamInfos ${JSON.stringify(teamInfos)}`)

      // Not end list yet
      if (teamInfos.length > 0) {
        let endOfList = teamInfos[teamInfos.length - 1][0]
        if (endOfList === false) {
          // clean duplicated
          let uniqueTeamInfos = []
          let foundTeamNames = []
          for (let teamInfo of teamInfos) {
            let teamName = teamInfo[2]
            if (foundTeamNames.indexOf(teamName) === -1) {
              uniqueTeamInfos.push(teamInfo)
              foundTeamNames.push(teamName)
            }
          }
          teamInfos = uniqueTeamInfos
        }
      }

      console.log(`unique teamInfos ${JSON.stringify(teamInfos)}`)

      // console.log(`teamInfos ${teamInfos}`)
      let teamProfiles = teamInfos.map(async (teamInfo) => {
        // console.log(`teamInfo ${teamInfo}`)
        let [
          endOfList,
          nextStartSearchingIndex,
          teamName,
          totalVoted
        ] = teamInfo

        console.log(`nextStartSearchingIndex ${nextStartSearchingIndex}`)

        if (endOfList) {
          console.log(`endOfList ${endOfList}`)
        }
        console.log('teamName: ' + teamName)
        console.log('totalVoted: ' + totalVoted + '\n')
        // const {teams, canVote} = await this.getPlayersProfile(teamName)
        // console.log('canVote' + canVote)

        data = {
          // member: teams,
          // canVote: canVote,
          score: await this.getVotingPointForTeam(teamName)
        }
        // console.log('checkCanVote: ' + data.member[0].address + '\n')

        const teamProfile = {
          name: teamName,
          // members: data.member,
          // canVote: data.canVote,
          score: data.score
        }
        console.log('profile >> ' + JSON.stringify(teamProfile))

        return teamProfile
      })
      const dataTeams = await Promise.all(teamProfiles)

      // dataTeams = teamProfiles

      console.log('dataTeams >>  ' + JSON.stringify(dataTeams))

      return dataTeams
    } catch (error) {
      console.error(error)
    }
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
        gas: 350000,
        gasPrice: 10000000000
      })
      console.log(res)
    } catch (error) {
      console.error(error)
    }
    console.log('... succeeded')
  }

  async getTotalVotersToTeam (teamName) {
    let totalVoters = 0

    console.log('\nQuerying for a total number of voters to the specific team --> "' + teamName + '" ...')
    try {
      totalVoters = await this.team.methods.getTotalVotersToTeam(teamName).call({})
    } catch (error) {
      console.error(error)
    }
    return totalVoters
  }

  async getVotingPointForTeam (teamName) {
    let totalVoters = 0

    console.log('\nQuerying for a total number of voters to the specific team --> "' + teamName + '" ...')
    try {
      totalVoters = await this.team.methods.getVotingPointForTeam(teamName).call({})
    } catch (error) {
      console.error(error)
    }
    return totalVoters
  }

  async startVoting (projectDeployerAddr) {
    let state

    // Change all contracts' state from RegistrationLocked to Voting
    console.log("\nChanging the contracts' state to Voting ...")
    try {
      await this.main.methods.startVoting().send({
        from: projectDeployerAddr,
        gas: 1000000,
        gasPrice: 10000000000
      })
      console.log('... succeeded')
    } catch (error) {
      console.error(error)
    }

    try {
      // Check the contracts' state
      console.log("\nValidating the contracts' state ...")
      state = await this.main.methods.getContractState().call({
        from: projectDeployerAddr
      })
      console.log('... succeeded --> ' + state)
    } catch (error) {
      console.error(error)
    }
  }

  async stopVoting (projectDeployerAddr) {
    let state

    // Change all contracts' state from RegistrationLocked to Voting
    console.log("\nChanging the contracts' state to Voting ...")
    try {
      await this.main.methods.stopVoting().send({
        from: projectDeployerAddr,
        gas: 1000000,
        gasPrice: 10000000000
      })
      console.log('... succeeded')
    } catch (error) {
      console.error(error)
    }

    try {
      // Check the contracts' state
      console.log("\nValidating the contracts' state ...")
      state = await this.main.methods.getContractState().call({
        from: projectDeployerAddr
      })
      console.log('... succeeded --> ' + state)
    } catch (error) {
      console.error(error)
    }
  }

  async voteTeam ({voterAddr, teamName, votingWeight}) {
    console.log('\nVoting to a team -->  team: "' + teamName + '" weight: "' + votingWeight + '" form ' + voterAddr)
    // Vote to a team
    try {
      await this.main.methods.voteTeam(teamName, parseInt(votingWeight)).send({
        from: voterAddr,
        gas: 1000000,
        gasPrice: 1000000000
      })
      console.log('... succeeded voteTeam')
      return true
    } catch (error) {
      console.error(error)
      return false
    }
  }

  async kickTeam (teamName) {
    console.log('\nKicking team --> "' + teamName + '" ...')
    try {
      await this.main.methods.kickTeam(teamName).send({
        from: this.account,
        gas: 1000000,
        gasPrice: 10000000000
      })
    } catch (error) {
      console.error(error)
    }
  }

  // ///////////////// //
  // ---- PLAYER ----  //
  // ///////////////// //
  async getPlayersProfile (teamName) {
    let playerCount = await this.getPlayerCountInTeam(teamName)
    console.log(`playerCount: ${playerCount}`)
    let teams = []

    let nextStartSearchingIndex = 0
    let endOfList, playerAddress
    let canVote = true
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
      if (playerAddress === this.account) {
        canVote = false
        console.log(playerAddress + 'booommm' + this.account)
      }
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
    return {teams, canVote}
  }

  async isPlayer (address) {
    console.log(`isPlayer >> ${address}`)

    let isPlayer = await this.player.methods.isPlayer(address).call()
    console.log(`isPlayer >> ${isPlayer}`)

    return isPlayer
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
        gas: 1000000,
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
        gas: 1000000,
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
    let name = await this.staff.methods.getStaffName(address).call()
    return name
  }
  async isStaff (address) {
    console.log(`ddd >> ${address}`)

    let isStaff = await this.staff.methods.isStaff(address).call()
    console.log(`dddIs >> ${isStaff}`)

    return isStaff
  }
  async lockRegistration (projectDeployerAddr) {
    console.log('lockRegis')
    try {
      await this.main.methods.lockRegistration().send({
        from: projectDeployerAddr,
        gas: 1000000,
        gasPrice: 10000000000
      })
    } catch (error) {
      console.error(error)
    }
  }

  async getContractState (projectDeployerAddr) {
    let state
    try {
      // Check the contracts' state
      console.log("\nValidating the contracts' state ...")
      state = await this.main.methods.getContractState().call({
        from: projectDeployerAddr
      })
      console.log('check state --> ' + state)
      console.log('... succeeded --> ' + state)
    } catch (error) {
      console.error(error)
    }
    return state
  }

  // /////////////////// //
  // ---- ETHEREUM ----  //
  // /////////////////// //
  async getNetworkName () {
    const network = await this.web3.eth.net.getNetworkType()
    return network
  }
}

Object.setPrototypeOf(PizzaCoin.prototype, {...validateConnection})

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
