<template>
  <div id="app">
    <div class="container is-fluid">
      <div class="columns is-mobile is-desktop is-widescreen is-fullhd">
        <div class="column in-one-half">
            <ChartComponent/>
        </div>
        <div class="column in-one-half">
          <TwitterComponent/>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ChartComponent from './components/charts/Charts.vue'
import TwitterComponent from './components/twitter/Twitter'

export default {
  name: 'app',
  components: {
    ChartComponent,
    TwitterComponent
  }
}
</script>

<style>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
