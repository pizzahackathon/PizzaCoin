<template>
  <div class="home">
      <div class="container">
        <div class="columns is-mobile">
          <HelloWorld />
        </div>
      </div>

  </div>
</template>

<script>
// @ is an alias to /src
import HelloWorld from '@/components/HelloWorld.vue'
import ProposalCard from '@/components/ProposalCard.vue'

export default {
  name: 'home',
  components: {
    HelloWorld,
    ProposalCard
  }
}
</script>
