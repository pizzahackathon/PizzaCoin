<template>
  <div id="app" class="">
    <div id="nav" class="nav-bar">
     <nav class="navbar is-transparent is-warning">
      <div class="navbar-brand">
        <router-link to="/" class="navbar-item">
          <img class="logo" src="https://p-u.popcdn.net/attachments/images/000/010/730/large/Pizza_Hackathon_Logo.png?1532094493" alt="Pizza Hackathon" width="50" height="50">
        </router-link>
      </div>

      <div id="navbarExampleTransparentExample" class="navbar-menu">
        <div class="navbar-start">
          <div class="navbar-item">
            <router-link to="/" class="navbar-item link-item">
              Home
            </router-link>
            <router-link to="/leader-board" class="navbar-item link-item">
              Leader board
            </router-link>
            <router-link to="/livefeed" class="navbar-item link-item">
              Live feed
            </router-link>
            <router-link to="/github" class="navbar-item link-item">
              Github
            </router-link>
          </div>
        </div>
        <div class="navbar-end">
          <div class="navbar-item">
            {{ playerInfo }}
          </div>
          <div class="navbar-item">
            <a :href="`${$store.state.system.etherscanPrefix}/token/${$store.state.system.pizzaCoinAddr}?a=${$pizzaCoin.account}`" class="bd-tw-button button is-info" target="_blank"> You have {{ tokenBalance }} PZC</a>
          </div>
          <div class="navbar-item">
            <div class="field is-grouped">
              <p class="control" v-if="isStaffLoggedIn && stateContract === 'Registration'">
                <a class="bd-tw-button button"  @click="lockRegistration()">
                    Freeze & Transfer
                </a>
              </p>
              <p class="control">
                <a class="bd-tw-button button" @click="startVote()" v-if="isStaffLoggedIn && stateContract === 'Registration Locked'">
                    Start Vote
                </a>
                <a class="bd-tw-button button" @click="stopVote()" v-if="isStaffLoggedIn && stateContract === 'Voting'">
                    Stop Vote
                </a>
              </p>
            </div>
          </div>
        </div>
      </div>
      </nav>
    </div>
     <section>
       <span
        class="icon"
        @click="isComponentModalActive = true"
        v-if="stateContract === 'Registration' && !(isStaffLoggedIn || isPlayerLoggedIn)">
         <i class="fas fa-plus-circle fa fa-2x"></i>
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
    account: null
    // playerInfo: ''
  }),
  async mounted () {
    console.log('check state --> ')
    try {
      let state = await this.$pizzaCoin.getContractState(await this.$pizzaCoin.account)
      console.log('check state --> ' + state)
      this.$store.dispatch('staff/getContractState', state)
    } catch (error) {
      console.error(error)
    }
  },
  computed: {
    ...mapState('auth', ['isStaffLoggedIn', 'tokenBalance', 'isPlayerLoggedIn', 'playerInfo']),
    ...mapState('staff', ['stateContract'])
  },
  methods: {
    ...mapActions('auth', ['isStaffLogin']),
    ...mapActions('team', ['creatTeam']),
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
.main {
  margin-top: 2ex;
}
.icon {
   position: absolute;
   top: 80px;
   right: 30px;
}
.icon:hover {
  opacity: 0.8;
  cursor: pointer;
}
.navbar-brand {
  padding-left: 2em;
}
</style>
<style scoped>
.nav-bar {
  box-shadow:0 0 10px #333 !important;
}
.logo {
  max-height: 3.75em;
}
.router-link-exact-active {
  font-weight: bold;
  color: blue;
}
.link-item {
  font-size: 1.1em;
  margin-left: 3px;
  margin-right: 3px;
}
</style>
