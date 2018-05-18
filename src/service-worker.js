/* global workbox */
/* eslint-disable no-restricted-globals */

// eslint-disable-next-line no-underscore-dangle
workbox.precaching.precacheAndRoute(self.__precacheManifest || []);

// Cache the index page
workbox.routing.registerRoute(
    context => context.url.pathname.indexOf('/api') !== 0 && context.url.pathname.indexOf('/assets') !== 0,
    workbox.strategies.cacheFirst({
        cacheName: 'pages',
        plugins: [
            new workbox.expiration.Plugin({
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
