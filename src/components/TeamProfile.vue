<template>
    <div class="players-box">
        <div
          class="main level is-mobile player"
            v-for="member in team.members"
            :key="member.address"
              >
          <a :href="`${$store.state.system.etherscanPrefix}/address/${member.address}`" target="_blank">
            <div class="level-item has-text-centered">
              <div>
                <img :src="playerAvatarImage(member.address)" alt="">
              </div>
              <div>
                  <div class="playerName">
                    {{ member.name }}
                  </div>
              </div>
          </div>
          </a>
          <div class="level-item has-text-centered">
              <div>
                  <!-- <div>{{ member.address }}</div> -->
              </div>
          </div>
          <div class="level-item has-text-centered" v-if="isLoggedIn && stateContract === 'Registration'">
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
        <button
            class="button is-primary"
             @click="onVote(team)"
             v-if="stateContract === 'Voting' && parseInt(tokenBalance) > 0"
            >
            VOTE
        </button>
        <div v-if="stateContract === 'Registration'">
          <button
            class="button is-success"
             @click="onJoin()"
             v-if="isJoined"
             :disabled="team.members.length > 4"
            >
            Join
          </button>
          <button
            class="button is-success"
          >
            KickTeam
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
    // team: {
    //   members: [
    //     {
    //       name: 'abc',
    //       address: '0xfcee22fcc5607812db42371d9f75cf527e44718a'
    //     },
    //     {
    //       name: 'abc',
    //       address: '0x786f95663b1feaa429fe608dd51946356f9e6d54'
    //     },
    //     {
    //       name: 'abc',
    //       address: '0x950807aeaccb5e66dc09e9f99a7d559a880d8b14'
    //     },
    //     {
    //       name: 'abc',
    //       address: '0x69f6829b0a62c34a844e9a0a123dd4b1822a7bc5'
    //     },
    //     {
    //       name: 'abc',
    //       address: '0xdea6af9e0d4a7ac7e639b1c5751b58c165af590b'
    //     }
    //   ]
    // }
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
.players-box {
  display: flex;
  flex-flow: row wrap;
}
.player {
  display: inline-block;
  margin: 10px 0 0 10px;
  flex-grow: 1;
  height: 100px;
}
.level-item {
  display: block !important;
}
.playerName {
  font-size: 22px;
}
</style>
