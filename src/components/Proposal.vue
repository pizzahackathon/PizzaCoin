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
                            @click="removeMember(member)"
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
        <form @submit.prevent="onAddMember(team)">
            <b-input
                v-if="!isJoined"
                type="text"
                v-model="memberName"
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
    memberName: '',
    pizzaCoin: null,
    pizzaCoinSymbol: '',
    userAddress: ''
  }),
  async mounted () {
    await this.loadPizzaCoinSymbol()
  },
  props: ['team'],
  computed: mapState('auth', ['user', 'isLoggedIn']),
  methods: {
    ...mapActions('team', ['addMember']),
    ...mapMutations('team', ['removeMember']),
    ...mapMutations('team', ['addScore']),
    onVote: function (team) {
      this.addScore(team)
    },
    onJoin () {
      this.isJoined = false
    },
    async onAddMember (team) {
      const user = {
        memberName: this.memberName,
        teamMebers: team
      }
      await this.addMember(user)
      this.memberName = ''
      this.isJoined = true
    },

    async loadPizzaCoinSymbol () {
      this.pizzaCoinSymbol = await this.$pizzaCoin.main.methods.symbol().call()
      this.userAddress = this.$pizzaCoin.account
    }
  }
}
</script>
<style>
.main {
    margin-top: 5em;
}
</style>
