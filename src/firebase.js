import firebase from 'firebase'

const config = {
  apiKey: 'AIzaSyBjHLAk7aXbDs8lAkv7S1fc9_sZHSN5BeQ',
  authDomain: 'weathersample-9f39d.firebaseapp.com',
  databaseURL: 'https://weathersample-9f39d.firebaseio.com',
  projectId: 'weathersample-9f39d',
  storageBucket: 'weathersample-9f39d.appspot.com',
  messagingSenderId: '756671422322'
}
firebase.initializeApp(config)

export default firebase
