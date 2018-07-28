import firebase from '@/firebase'
import store from '@/store'
import db from '@/db'

firebase.auth().onAuthStateChanged(function (user) {
  if (user) {
    if (user.user) {
      user = user.usr
    }
    const setUser = {
      id: user.uid,
      name: user.displayName,
      image: user.photoURL,
      create_at: firebase.firestore.FieldValue.serverTimestamp()
    }
    db.collection('users').doc(setUser.id).set(setUser)
    store.commit('auth/setUser', setUser)
  } else {
    store.commit('auth/setUser', null)
  }
})
