<template>
  <div id="app" class="is-white">
    <div id="nav">
     <nav class="navbar is-transparent is-warning">
      <div class="navbar-brand">
        <a class="navbar-item" href="#">
          <img src="https://p-u.popcdn.net/attachments/images/000/010/730/large/Pizza_Hackathon_Logo.png?1532094493" alt="Pizza Hackathon" width="50" height="50">
        </a>
      </div>

      <div id="navbarExampleTransparentExample" class="navbar-menu">
        <div class="navbar-start">
          <div class="navbar-item">
            <a href="/leader-board" class="bd-tw-button button">Leader board</a>
          </div>
          <div class="navbar-item">
            <a href="/leader-board" class="bd-tw-button button is-info"> You have {{ tokenBalance }} Token</a>
          </div>
        </div>
        <div class="navbar-end">
          <div class="navbar-item">
            {{ playerInfo }}
          </div>
          <div class="navbar-item">
            <div class="field is-grouped">
              <p class="control" v-if="isLoggedIn && stateContract === 'Registration'">
                <a class="bd-tw-button button"  @click="lockRegistration()">
                    Freeze & Transfer
                </a>
              </p>
              <p class="control">
                <a class="bd-tw-button button" @click="startVote()" v-if="isLoggedIn && stateContract === 'Registration Locked'">
                    Start Vote
                </a>
                <a class="bd-tw-button button" @click="stopVote()" v-if="isLoggedIn && stateContract === 'Voting'">
                    Stop Vote
                </a>
              </p>
            </div>
          </div>
        </div>
      </div>
      </nav>
        <!-- <router-link to="/">Home</router-link> |
        <router-link to="/web3Example">Web3 Example</router-link> | -->
    </div>
     <section>
       <span class="icon" @click="isComponentModalActive = true">
         <i class="fas fa-plus-circle fa fa-3x"></i>
       </span>

        <b-modal :active.sync="isComponentModalActive" has-modal-card>
            <!-- <modal-form v-bind="teamname"> -->
                <form @submit.prevent="onCreateTeam()">
                <div class="modal-card" style="width: auto">
                    <header class="modal-card-head">
                        <p class="modal-card-title">Place your name</p>
                    </header>
                    <section class="modal-card-body">
                        <b-field label="User name">
                            <b-input
                                type="text"
                                v-model="creatorName"
                                placeholder="Your name"
                                required>
                            </b-input>
                        </b-field>
                        <b-field label="teamname">
                            <b-input
                                type="text"
                                v-model="teamname"
                                placeholder="Your team name"
                                required>
                            </b-input>
                        </b-field>
                    </section>
                    <footer class="modal-card-foot">
                        <button class="button" type="button" @click="onCancel()">Cancel</button>
                        <button class="button is-primary">Submit</button>
                    </footer>
                </div>
            </form>
            <!-- </modal-form> -->
        </b-modal>
    </section>
    <router-view class="main"/>
  </div>
</template>

<script>
import { mapActions, mapState } from 'vuex'

export default {
  data: () => ({
    isComponentModalActive: false,
    creatorName: '',
    teamname: '',
    account: null,
    playerInfo: ''
  }),
  async mounted () {
    console.log('check state --> ')
    try {
      let state = await this.$pizzaCoin.getContractState(await this.$pizzaCoin.account)
      console.log('check state --> ' + state)
      this.$store.dispatch('staff/getContractState', state)

      await this.getAccountInfo()
    } catch (error) {
      console.error(error)
    }
  },
  computed: {
    ...mapState('auth', ['isLoggedIn', 'tokenBalance']),
    ...mapState('staff', ['stateContract'])
  },
  methods: {
    ...mapActions('auth', ['isStaffLogin']),
    ...mapActions('team', ['creatTeam']),
    async getAccountInfo () {
      let isPlayer = await this.isPlayer()
      if (isPlayer) {
        this.playerInfo = 'Player: ' + await this.$pizzaCoin.getPlayerName(this.$pizzaCoin.account)
      } else {
        this.playerInfo = 'Staff: ' + await this.$pizzaCoin.getStaffName(this.$pizzaCoin.account)
      }
    },
    async onCreateTeam () {
      try {
        this.isComponentModalActive = false
        await this.$pizzaCoin.createTeam(this.creatorName, this.teamname)
        this.$store.dispatch('team/getTeamsProfile', await this.$pizzaCoin.getTeamsProfile())
        this.creatorName = ''
        this.teamname = ''
      } catch (error) {
        console.error(error)
      }
    },
    onCancel () {
      this.teamname = ''
      this.isComponentModalActive = false
    },
    async startVote () {
      console.log('start vote' + await this.$pizzaCoin.account)
      try {
        await this.$pizzaCoin.startVoting(await this.$pizzaCoin.account)
      } catch (error) {
        console.error(error)
      }
    },
    async isPlayer () {
      try {
        return await this.$pizzaCoin.isPlayer(this.$pizzaCoin.account)
      } catch (error) {
        console.error(error)
      }
    },
    async stopVote () {
      console.log('stop vote' + this.$pizzaCoin.account)
      try {
        await this.$pizzaCoin.stopVoting(await this.$pizzaCoin.account)
      } catch (error) {
        console.error(error)
      }
    },
    async lockRegistration () {
      try {
        await this.$pizzaCoin.lockRegistration(await this.$pizzaCoin.account)
      } catch (error) {
        console.error(error)
      }
    }
  }
}
</script>
<style>
#app {
  position: relative;
}
.app {
  background: #C3CBE2;
}
.main {
  margin-top: 2ex;
}
.icon {
   position: absolute;
   top: 80px;
   right: 100px;
}
.icon:hover {
  opacity: 0.8;
  cursor: pointer;
}
.navbar-brand {
  padding-left: 2em;
}
</style>
