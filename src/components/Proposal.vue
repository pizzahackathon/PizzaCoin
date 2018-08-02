<template>
    <div>
        <div
            class="main level is-mobile"
             v-for="member in members.detail"
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
             @click="onVote(members)"
            >
            VOTE
        </button>
        <button
            class="button is-success"
             @click="onJoin()"
             v-if="isJoined"
             :disabled="members.detail.length > 4"
            >
            Join
        </button>
        <form @submit.prevent="onAddMember(members)">
            <b-input
                v-if="!isJoined"
                type="text"
                v-model="memberName"
                placeholder="Your name"
                required>
            </b-input>
        </form>
    </div>
</template>
<script>
import { mapMutations, mapState, mapActions } from 'vuex'

export default {
  data: () => ({
    isJoined: true,
    memberName: ''
  }),
  props: ['members'],
  computed: mapState('auth', ['user', 'isLoggedIn']),
  methods: {
    ...mapActions('team', ['addMember']),
    ...mapMutations('team', ['removeMember']),
    ...mapMutations('team', ['addScore']),
    onVote: function (members) {
      this.addScore(members)
    },
    onJoin () {
      this.isJoined = false
    },
    async onAddMember (members) {
      const user = {
        memberName: this.memberName,
        teamMebers: members
      }
      await this.addMember(user)
      this.memberName = ''
      this.isJoined = true
    }

  }
}
</script>
<style>
.main {
    margin-top: 5em;
}
</style>
