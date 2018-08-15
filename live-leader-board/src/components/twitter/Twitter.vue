<template>
  <div class="is-fluid">
      <div class="box" v-if="twitterDatas" v-for="tweet in twitterDatas" :key="tweet.id" >
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
              <div v-if="tweet.entities.urls">
                <div v-for="url in tweet.entities.urls" :key="url.expanded_url">
                  <youtube :video-id="url.videosId"></youtube>
                </div>
              </div>
              <div v-if="tweet.entities.media">
                <div v-for="media in tweet.entities.media" :key="media.media_url_https">
                  <img :src="media.media_url_https">
                </div>
              </div>
              <br>
              <time >{{tweet.created_at | formatDate}}</time>
          </div>
      </div>
  </div>
</template>
<script>
import axios from 'axios'
import _ from 'lodash'

export default {
  name: 'TwitterComponent',
  data () {
    return {
      twitterDatas: [],
      videosId: null
    }
  },
  async mounted () {
    const instance = axios.create({
      baseURL:
        'https://us-central1-live-leader-board.cloudfunctions.net/restApi',
      headers: {
        'Content-Type': 'application/json'
      }
    })

    for (let i = 0; i <= 10; i++) {
      this.loadTweets(instance)
      await this.sleep(10)
    }
  },
  methods: {
    async loadTweets (instance) {
      const response = await instance.get('/loadTweets/%23pizzahackathon')
      console.log(response.data.statuses)
      this.twitterDatas = response.data.statuses
      _.forEach(this.twitterDatas, (tweet) => {
        if (tweet.entities.urls) {
          _.forEach(tweet.entities.urls, (url) => {
            // console.log("url: ",url.expanded_url);
            // console.log("videoId: ",this.$youtube.getIdFromURL(url.expanded_url))
            url.videosId = this.$youtube.getIdFromURL(url.expanded_url)
          })
        }
      })
    },
    sleep (time) {
      return new Promise(resolve => setTimeout(resolve, time * 1000))
    }
  }
}
</script>
