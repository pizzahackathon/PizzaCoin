<template>
  <div id="app">
    <div id="nav">
     <nav class="navbar is-transparent is-warning">
      <div class="navbar-brand">
        <a class="navbar-item" href="https://bulma.io">
          <img src="https://p-u.popcdn.net/attachments/images/000/010/730/large/Pizza_Hackathon_Logo.png?1532094493" alt="Bulma: a modern CSS framework based on Flexbox" width="50" height="50">
        </a>
      </div>

      <div id="navbarExampleTransparentExample" class="navbar-menu">
        <div class="navbar-end">
          <div class="navbar-item">
            <div class="field is-grouped">
              <p class="control" v-if="!isLoggedIn">
                <a class="bd-tw-button button" @click="login()">
                    Login
                </a>
              </p>
              <p class="control" v-if="isLoggedIn">
                <a class="bd-tw-button button">
                    Freeze & Transfer
                </a>
              </p>
              <p class="control" v-if="isLoggedIn">
                <a class="bd-tw-button button">
                    Start/Stop Vote
                </a>
              </p>
              <p class="control" v-if="isLoggedIn">
                <a class="bd-tw-button button" @click="logout()">
                    Logout
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
    teamname: ''
  }),
  computed: mapState('auth', ['user', 'isLoggedIn']),
  methods: {
    ...mapActions('auth', ['login', 'logout']),
    ...mapActions('team', ['creatTeam']),
    async onCreateTeam () {
      // // console.log(this.teamname)
      // await this.creatTeam(this.teamname)
      // this.teamname = ''
      // this.isComponentModalActive = false

      this.$pizzaCoin.createTeam(this.creatorName, this.teamname)
    },
    onCancel () {
      this.teamname = ''
      this.isComponentModalActive = false
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
