<template>
  <div class="container is-fluid">
      <div class="columns is-mobile is-desktop">
        <div class="column in-one-third">
            <div class="card" v-if="twitterDatas" v-for="tweet in twitterDatas" :key="tweet.id" >
                <div class="card-content">
                    <div class="media">
                        <div class="media-left">
                            <figure class="image is-64x64">
                            <img :src="tweet.user.profile_image_url_https" alt="Placeholder image">
                            </figure>
                        </div>
                        <div class="media-content">
                            <p class="title is-4">{{tweet.user.name}}</p>
                            <p class="subtitle is-6">@{{tweet.user.name}}</p>
                        </div>
                    </div>
                    <div class="content has-text-left">
                        {{tweet.text}}
                        <br>
                        <time >{{tweet.created_at | formatDate}}</time>
                    </div>
                </div>
            </div>
        </div>
        <div class="column in-one-third">

        </div>
        <div class="column in-one-third">

        </div>
      </div>
  </div>
</template>
<script>
import axios from 'axios'

export default {
  name: 'TwitterComponent',
  data () {
    return {
      twitterDatas: []
    }
  },
  mounted () {
    const instance = axios.create({
      baseURL: 'https://us-central1-live-leader-board.cloudfunctions.net/restApi',
      headers: {
        'Content-Type': 'application/json'
      }
    })
    this.loadTweets(instance)
  },
  methods: {
    async loadTweets (instance) {
      const response = await instance.get('/loadTweets')
      console.log(response.data.statuses)
      this.twitterDatas = response.data.statuses
    }
  }
}
</script>
