<template>
    <div>
        <div
            class="main level is-mobile"
             v-for="member in team.members"
             :key="member.address"
                >
            <div class="level-item has-text-centered">
                    <div>
                        <div>{{ member.name }}</div>
                    </div>
                </div>
                <div class="level-item has-text-centered">
                    <div>
                        <div>{{ member.address }}</div>
                    </div>
                </div>
                <div class="level-item has-text-centered" v-if="isLoggedIn">
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
            >
            VOTE
        </button>
        <button
            class="button is-success"
             @click="onJoin()"
             v-if="isJoined"
             :disabled="team.members.length > 4"
            >
            Join
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

        <h2>Pizza Coin</h2>
        <div>
          <label>Symbol </label>
          {{ pizzaCoinSymbol }}
          <br>
          <label>Address </label>
          {{ userAddress }}
        </div>
    </div>
</template>
<script>
import { mapMutations, mapState, mapActions } from 'vuex'

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
    ...mapState('auth', ['user', 'isLoggedIn'])
  },
  methods: {
    ...mapActions('team', ['addMember']),
    ...mapMutations('team', ['addScore']),
    async onVote ({name}) {
      console.log('onVote --> ' + await name)
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
