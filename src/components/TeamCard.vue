<template>
  <div class="column is-4">
    <a href="#" class="badge1" :data-badge="score"></a>
    <div class="box content shadow">
      <article class="post">
        <h2 class="">
            {{team.name}}
        </h2>
        <hr>
        <div class="">
            <TeamProfile
                :team="team"
            />
        </div>
      </article>
    </div>
  </div>
</template>

<script>
import TeamProfile from '@/components/TeamProfile.vue'

export default {
  name: 'TeamProfileCard',
  props: ['team', 'score'],
  components: {
    TeamProfile
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
   top:-15px;
   right:-450px;
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
</style>
