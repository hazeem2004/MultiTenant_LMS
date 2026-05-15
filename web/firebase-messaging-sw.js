// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here. Other Firebase libraries
// are not available in the service worker.
// 
// This file is required to prevent "failed-service-worker-registration" errors
// when running Flutter Web with Firebase Messaging.

self.addEventListener('push', function(event) {
  console.log('[firebase-messaging-sw.js] Received background push message.', event);
});
