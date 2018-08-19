<template>
  <div class="is-fluid">
      <div class="box " v-if="twitterDatas" v-for="tweet in twitterDatas" :key="tweet.id" >
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
              <div class="media-right">
                <a href="#" class="button is-danger" @click="deleteTweet(tweet)">
                  X
                </a>
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
import config from '@/config.js'
import swal from 'sweetalert2'

export default {
  name: 'TwitterComponent',
  data () {
    return {
      twitterDatas: [],
      videosId: null,
      instance: null,
      queryString: ''
    }
  },
  async mounted () {
    this.instance = axios.create({
      baseURL:
        config.twitter.endPoint,
      headers: {
        'Content-Type': 'application/json'
      }
    })
    this.prepareQueryString()
    if (config.isProd) {
      this.runTweetProd()
    } else {
      this.runTweetDev()
    }
  },
  methods: {
    prepareQueryString () {
      _.forEach(config.twitter.queryParam, (query, idx, array) => {
        this.queryString += '%23' + query
        if (idx !== array.length - 1) {
          this.queryString += '%20OR%20'
        }
      })
    },
    async runTweetDev () {
      for (let i = 0; i <= 1; i++) {
        this.loadTweets(this.instance)
        await this.sleep(10)
      }
    },
    async runTweetProd () {
      for (;;) {
        this.loadTweets(this.instance)
        await this.sleep(10)
      }
    },
    async loadTweets (instance) {
      const response = await instance.get(this.queryString)
      // console.log(response.data.statuses)
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
    },
    deleteTweet (tweet) {
      swal({
        title: 'ยืนยันการทำรายการ',
        type: 'warning',
        showCancelButton: true,
        confirmButtonText: 'ตกลง',
        cancelButtonText: 'ยกเลิก'
      }).then((result) => {
        if (result.value) {
          _.remove(this.twitterDatas, (data) => {
            return data.id === tweet.id
          })
          this.twitterDatas = this.twitterDatas.slice()
        }
      })
    }
  }
}
</script>
