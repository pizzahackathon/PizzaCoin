<template>
    <div class="column is-4">
        <!-- <vcl-instagram v-if="!team"></vcl-instagram> -->
        <div class="box">
            <article class="media">
                <div class="media-content">
                    <div class="content">
                        <div class="message-header has-text-centered">
                            {{team.name}}
                            <button class="button is-primary">{{ team.score }}</button>
                        </div>
                        <br>
                        <hr>
                        <div>
                            <TeamProfile
                                :team="team"
                            />
                        </div>
                    </div>
                </div>
            </article>
        </div>
    </div>
</template>

<script>
import TeamProfile from '@/components/TeamProfile.vue'

export default {
  name: 'TeamProfileCard',
  props: ['team'],
  components: {
    TeamProfile
  }
}
</script>

<style>
</style>
