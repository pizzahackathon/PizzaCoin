<template>
    <div class="">
        <div
          class="is-mobile"
            v-for="member in dataTeam"
            :key="member.address"
              >
            <div class="media content-margin">
                  <div class="media-left">
                      <a :href="`${$store.state.system.etherscanPrefix}/address/${member.address}`" target="_blank">
                      <p class="image is-48x48">
                        <img :src="playerAvatarImage(member.address)" alt="" class="img-player">
                      </p>
                      </a>
                    </div>
                    <div class="media-content">
                        <div>
                          <div class="playerName">
                             <h4>{{ member.name }}</h4>
                          </div>
                          <h6 class="userAdress">{{ member.address }}</h6>
                        </div>
                    </div>
                    <div
                     class="media-right"
                     v-if="isStaffLoggedIn && stateContract === 'Registration'"
                      >
                      <div>
                          <button
                              class="button is-danger"
                              @click="removePlayer(team, member)"
                              >
                                  Kick
                          </button>
                      </div>
                    </div>
            </div>
        </div>
        <button
            class="button is-primary is-fullwidth"
             @click="onVote(team)"
             v-if="stateContract === 'Voting' && parseInt(tokenBalance) > 0 && canVote"
            >
            VOTE
        </button>
        <div v-if="!isStaffLoggedIn && stateContract === 'Registration'" class="join">
          <button
            class="button is-success is-fullwidth"
             @click="onJoin()"
             v-if="isJoined && !isPlayerLoggedIn"
             :disabled="dataTeam.length > 4"
            >
            Join
          </button>
          <form
            @submit.prevent="onAddPlayer(team)"
            >
              <b-input
                  v-if="!isJoined"
                  type="text"
                  v-model="playerName"
                  placeholder="Your name"
                  required>
              </b-input>
          </form>
          <button
            class="button is-primary is-fullwidth join"
             @click="onAddPlayer(team)"
              v-if="!isJoined"
            >
            Submit
          </button>
        </div>
        <button
          class="button is-danger is-fullwidth join"
            @click="removeTeam(team.name)"
            v-if="dataTeam.length === 0 && isStaffLoggedIn && stateContract === 'Registration'"
          >
          Kick team
        </button>
    </div>
</template>
<script>
import { mapMutations, mapState, mapActions } from 'vuex'
import Identicon from 'identicon.js'

export default {
  data: () => ({
    isJoined: true,
    playerName: '',
    pizzaCoin: null,
    pizzaCoinSymbol: '',
    userAddress: '',
    dataTeam: null,
    canVote: null
  }),
  async created () {

  },
  async mounted () {
    await this.loadPizzaCoinSymbol()
    // // this.dataTeam = await this.team
    // console.log('props'+ this.team.name)
    // let {teams, canVote} = await this.$pizzaCoin.getPlayersProfile(this.team.name)
    // this.dataTeam = teams
    // console.log('canVote' + canVote)
    if (this.stateContract !== 'Registration') {
      let {teams, canVote} = await this.$pizzaCoin.getPlayersProfile(this.team.name)
      this.dataTeam = teams
      this.canVote = canVote
      console.log('test' + this.dataTeam.length)
    }
    console.log('stateContract' + this.stateContract)
    while (this.stateContract === 'Registration') {
      let {teams} = await this.$pizzaCoin.getPlayersProfile(this.team.name)
      this.dataTeam = teams
    }
  },
  props: ['team'],
  computed: {
    ...mapState('auth', ['user', 'isStaffLoggedIn', 'tokenBalance', 'isPlayerLoggedIn']),
    ...mapState('staff', ['stateContract'])
  },
  methods: {
    ...mapActions('team', ['addMember']),
    ...mapMutations('team', ['addScore']),
    async onVote ({name}) {
      console.log('onVote --> ' + name)
      if (this.tokenBalance < 1) {
        alert('Your toker is not enough.')
      } else {
        try {
          const voteTeamData = {
            voterAddr: this.userAddress,
            teamName: name,
            votingWeight: 1
          }
          await this.$pizzaCoin.voteTeam(voteTeamData)
          this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
        } catch (error) {
          console.error(error)
        }
      }
    },
    onJoin () {
      this.playerName = ''
      this.isJoined = false
    },
    async onAddPlayer ({name}) {
      this.isJoined = true
      console.log('onAddPlayer --> ' + await name)
      console.log('playerName --> ' + this.playerName)
      const registerPlayerData = {
        playerAddr: this.userAddress,
        playerName: this.playerName,
        teamName: name
      }
      try {
        await this.$pizzaCoin.registerPlayer(registerPlayerData)
        this.isJoined = true
        this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
      } catch (error) {
        console.error(error)
      }
    },
    async loadPizzaCoinSymbol () {
      try {
        this.pizzaCoinSymbol = await this.$pizzaCoin.main.methods.symbol().call()
        this.userAddress = await this.$pizzaCoin.account
      } catch (error) {
        console.log(error)
      }
    },
    async removePlayer ({name}, {address}) {
      console.log(`removePlayer --> ${address} in team ${name}`)
      const removePlayerData = {
        kickerAddr: this.userAddress,
        playerAddr: address,
        teamName: name
      }
      try {
        const res = await this.$pizzaCoin.kickPlayer(removePlayerData)
        console.log(`After delete ->> ${res}`)
        this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
      } catch (error) {
        console.error(error)
      }
    },
    async removeTeam (teamName) {
      // this.userAddress
      console.log(`teamName: ${teamName}`)
      try {
        const res = await this.$pizzaCoin.kickTeam(teamName)
        console.log(`After delete ->> ${res}`)
        this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
      } catch (error) {
        console.error(error)
      }
    },
    playerAvatarImage (address) {
      let data = new Identicon(address, 120).toString()
      return `data:image/png;base64,${data}`
    },
    loadTeam () {
      console.log('loadTeam')
    }
  }
}
</script>
<style>
.main {
    margin-top: 5em;
    font-size: 10px;
}
</style>
<style scoped>
.content-margin {
  margin-top: 5px;
}
.player {
  display: inline-block;
  margin: 5px 0 0 10px;
  flex-grow: 1;
  height: 100px;
}
.playerName {
  font-size: 12px;
  margin-top: 10px;
}
.join {
  margin-top: 10px;
}
.img-player {
  border-radius: 50%;
}
</style>
<style scoped>
.button {
  border-radius: 9999px !important;
}
</style>

<style scped>
@media only screen and (min-width:120px){
    .userAdress {
      font-size:20px;
      word-break: break-all;
    }
}
@media only screen and (min-width:320px){
    .userAdress {
      font-size:20px;
      word-break: break-all;
    }
}
@media only screen and (min-width:480px){
    .userAdress {
      font-size:20px;
      word-break: break-all;
    }
}
@media only screen and (min-width:769px){
    .userAdress {
      font-size:20px;
      word-break: break-all;
    }
}
@media only screen and (min-width:960px){
    .userAdress {
      font-size:20px;
      word-break: break-all;
    }
}
@media only screen and (min-width:1024px){
    .userAdress {
      font-size:20px;
      word-break: break-all;
    }
}
@media only screen and (min-width:1279px){
    .userAdress {
     font-size:20px;
    }
}
@media only screen and (min-width:1472px){
.userAdress {
   font-size:20px;
  }
}
@media only screen and (min-width:2000px){
.userAdress {
   font-size:20px;
  }
}
</style>
