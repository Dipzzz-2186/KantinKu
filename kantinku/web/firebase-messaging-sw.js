// filepath: c:\KantinKu\kantinku\web\firebase-messaging-sw.js
// Scripts for firebase and firebase messaging
importScripts("https://www.gstatic.com/firebasejs/9.2.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.2.0/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker by passing the generated config
const firebaseConfig = {
    apiKey: "AIzaSyCt2NnU_x8T1ldNJDUo_IqUXqvqRNOIvFY",
    authDomain: "kantinkuproject.firebaseapp.com",
    projectId: "kantinkuproject",
    storageBucket: "kantinkuproject.firebasestorage.app",
    messagingSenderId: "426566689277",
    appId: "1:426566689277:web:ad81f5534209d6f357f994",
    measurementId: "G-3EG5ERJK8E"
};

firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
    console.log('Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
    };

    self.registration.showNotification(notificationTitle,
        notificationOptions);
});