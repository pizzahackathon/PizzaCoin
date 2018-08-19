const isProd = false

// ----- Twitter config
const twitter = {
  queryParam: ['pizzahackathon', 'pizzahack', 'pizzahackaton'],
  endPoint: 'https://us-central1-live-leader-board.cloudfunctions.net/restApi/loadTweets/'
}

// ----- Price chart btc/eth config
const chart = {
  endPoint: 'https://api.coinmarketcap.com/v2/ticker/',
  btcMin: 6350.0000,
  btcMax: 6500.0000,
  ethMin: 290.0000,
  ethMax: 300.0000
}

export default {
  isProd,
  twitter,
  chart
}
