<template>
    <div>
        <div
            class="main level is-mobile"
             v-for="member in members.detail"
             :key="member.token"
                >
            <div class="level-item has-text-centered">
                    <div>
                        <div>{{ member.name }}</div>
                    </div>
                </div>
                <div class="level-item has-text-centered">
                    <div>
                        <div>{{ member.token }}</div>
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
            >VOTE</button>
    </div>
</template>
<script>
import { mapMutations, mapState } from 'vuex'

export default {
  props: ['members'],
  computed: mapState('auth', ['user', 'isLoggedIn']),
  methods: {
    ...mapMutations(['removeMember']),
    onVote: function (members) {
      this.$store.commit('addScore', members)
    }
  }
}
</script>
<style>
.main {
    margin-top: 5em;
}
</style>
