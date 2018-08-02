<template>
    <div class="column is-4">
        <div class="box">
            <article class="media">
                <div class="media-content">
                    <div class="content">
                        <div class="message-header has-text-centered">
                            {{team.groupName}}
                            <button class="button is-primary">{{ team.score }}</button>
                        </div>
                        <br>
                        <hr>
                        <div>
                            <Proposal
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
import Proposal from '@/components/Proposal.vue'

export default {
  name: 'proposalcard',
  props: ['team'],
  components: {
    Proposal
  }
}
</script>

<style>
</style>
