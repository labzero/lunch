/* eslint-disable no-restricted-globals */

import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute } from 'workbox-routing';
import { CacheFirst } from 'workbox-strategies';
import { ExpirationPlugin } from 'workbox-expiration';

// eslint-disable-next-line no-underscore-dangle
precacheAndRoute(self.__WB_MANIFEST || []);

// Cache fonts
registerRoute(
  new RegExp('https://fonts.(?:googleapis|gstatic).com/(.*)'),
  new CacheFirst({
    cacheName: 'googleapis',
    plugins: [
      new ExpirationPlugin({
        maxAgeSeconds: 30 * 24 * 60 * 60, // 24 hours
      }),
    ],
  }),
);

// eslint-disable-next-line no-unused-vars
self.addEventListener('install', event => {
  // Activate new service worker as soon as it's installed
  self.skipWaiting();
});
