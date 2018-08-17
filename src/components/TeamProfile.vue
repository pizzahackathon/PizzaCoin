<template>
    <div class="">
        <div
          class="is-mobile"
            v-for="member in team.members"
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
                          <h6>{{ member.address }}</h6>
                        </div>
                    </div>
                    <div
                     class="media-right"
                     v-if="isLoggedIn && stateContract === 'Registration'"
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
            class="button is-primary"
             @click="onVote(team)"
             v-if="stateContract === 'Voting' && parseInt(tokenBalance) > 0"
            >
            VOTE
        </button>
        <div v-if="stateContract === 'Registration'" class="join">
          <button
            class="button is-success is-fullwidth"
             @click="onJoin()"
             v-if="isJoined"
             :disabled="team.members.length > 4"
            >
            Join
          </button>
          <button
            class="button is-danger is-fullwidth join"
             @click="removeTeam(team.name)"
             v-if="team.members.length === 0 && isLoggedIn && stateContract === 'Registration'"
             :disabled="team.members.length > 4"
            >
            Kick team
          </button>
          <form @submit.prevent="onAddPlayer(team)">
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
    userAddress: ''
  }),
  async mounted () {
    await this.loadPizzaCoinSymbol()
  },
  props: ['team'],
  computed: {
    ...mapState('auth', ['user', 'isLoggedIn', 'tokenBalance']),
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
      } catch (error) {
        console.error(error)
      }
    },
    playerAvatarImage (address) {
      let data = new Identicon(address, 120).toString()
      return `data:image/png;base64,${data}`
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
