<template>
  <div class="column is-4">
    <a :href="`${$store.state.system.etherscanPrefix}/address/${$store.state.system.pizzaCoinAddr}#events`" class="badge1" :data-badge="score" target="_blank" v-if="stateContract === 'Voting'"></a>
    <div class="box content shadow">
      <article class="post">
        <h2 class="">
            {{team.name}}
        </h2>
        <hr>
        <div class="">
            <TeamProfile
                :team="dataTeam"
            />
        </div>
      </article>
    </div>
  </div>
</template>

<script>
import TeamProfile from '@/components/TeamProfile.vue'
import { mapState } from 'vuex'

export default {
  name: 'TeamProfileCard',
  computed: {
    ...mapState('staff', ['stateContract'])

  },
  props: ['team', 'score'],
  data: () => ({
    dataTeam: null
  }),
  components: {
    TeamProfile
  },
  async mounted () {
    this.dataTeam = this.team
    console.log(this.dataTeam.name + 'props' + this.team.name)
  }
}
</script>

<style scped>
.content-body {
  margin-top: 0px;
}
.badge1 {
   position:relative;
}
.badge1[data-badge]:after {
   content:attr(data-badge);
   position:absolute;
   font-size:1.5em;
   background:#167df0;
   color:white;
   width:25px;height:25px;
   text-align:center;
   line-height:18px;
   border-radius:50%;
   box-shadow:0 0 10px #333;
   font-size: 2em;
   width: 40px;
   height: 38px;
   justify-content: center;
   vertical-align: middle;
   padding-top: 9px;
}
@media only screen and (min-width:120px){
    .badge1[data-badge]:after {
      top:-15px;
      right:-320px;
    }
}
@media only screen and (min-width:320px){
    .badge1[data-badge]:after {
      top:-15px;
      right:-320px;
    }
}
@media only screen and (min-width:480px){
    font-size: 10em;
    .badge1[data-badge]:after {
      top:-15px;
      right:-770px;
    }
}
@media only screen and (min-width:769px){
    .badge1[data-badge]:after {
      top:-15px;
      right:-250px;
    }
}
@media only screen and (min-width:960px){
    .badge1[data-badge]:after {
      top:-15px;
      right:-320px;
    }
}
@media only screen and (min-width:1024px){
    .badge1[data-badge]:after {
      top:-15px;
      right:-320px;
    }
}
@media only screen and (min-width:1279px){
    .badge1[data-badge]:after {
      top:-15px;
      right:-390px;
    }
}
@media only screen and (min-width:1472px){
.badge1[data-badge]:after {
   top:-15px;
   right:-450px;
  }
}
@media only screen and (min-width:2000px){
.badge1[data-badge]:after {
   top:-15px;
   right:-450px;
}
}
</style>
