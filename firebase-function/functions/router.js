const express = require("express");
const OAuth = require("oauth");

const twitterKey = '[twitter key]';
const twitterSecret = '[twitter secret]';
const token = '[twitter token]';
const secret = '[twitter secret]';

const oauth = new OAuth.OAuth(
  "https://api.twitter.com/oauth/request_token",
  "https://api.twitter.com/oauth/access_token",
  twitterKey,
  twitterSecret,
  "1.0",
  null,
  "HMAC-SHA1"
);

const router = express.Router();

router.get("/loadTweets/:query", (req, res) => {
    let query = req.params.query;
    console.log("req.params: ",req.params);
    console.log("query: ",query);
    if(!query){
        query = '%23pizzahackathon';
    }else{
        query = encodeURIComponent(query);
    }
    oauth.get(
        'https://api.twitter.com/1.1/search/tweets.json?q='+query+'&result_type=mixed',
        token,
        secret,
        (err, data, response) => {
            if(err) {
                console.error(err);
            }
          //   console.log("response: ",response);
            console.log("data: ",data);
            res.send(JSON.parse(data));
        }
    );
  
});

module.exports = router;
