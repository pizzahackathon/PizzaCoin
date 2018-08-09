<template>
  <div id="app">
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
            <a class="bd-tw-button button">Leader board</a>
          </div>
        </div>
        <div class="navbar-end">
          <div class="navbar-item">
            <div class="field is-grouped">
              <p class="control" v-if="isLoggedIn">
                <a class="bd-tw-button button">
                    Freeze & Transfer
                </a>
              </p>
              <p class="control" v-if="isLoggedIn">
                <a class="bd-tw-button button" @click="startVote()">
                    Start/Stop Vote
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
    account: null
  }),
  async mounted () {
  },
  computed: mapState('auth', ['isLoggedIn']),
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
      console.log('start vote' + this.$pizzaCoin.account)
      try {
        await this.$pizzaCoin.startVoting(await this.$pizzaCoin.account)
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
