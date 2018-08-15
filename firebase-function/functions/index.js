const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
const router = require('./router')

const app = express();
 
app.use(cors({origin: true}));
app.use('/', router);

exports.restApi = functions.https.onRequest(app);