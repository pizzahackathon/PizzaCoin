<template>
  <div id="app">
    <ChartComponent/>
  </div>
</template>

<script>
import ChartComponent from './components/charts/Charts.vue'

export default {
  name: 'app',
  components: {
    ChartComponent
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
