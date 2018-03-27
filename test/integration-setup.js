/* eslint-env mocha */
/* eslint-disable no-multi-assign */

import puppeteer from 'puppeteer';
import singletons from './integration/singletons';

let browser;

before((done) => {
  puppeteer.launch({
    headless: false,
    slowMo: 10,
  }).then((b) => {
    browser = singletons.browser = b;
    browser.newPage().then((p) => {
      const page = singletons.page = p;
      let gotoInterval = setInterval(() => {
        page.goto('http://local.lunch.pink:3000/').then(() => {
          if (gotoInterval) {
            clearInterval(gotoInterval);
            gotoInterval = undefined;
            done();
          }
        }).catch(() => {});
      }, 1000);
    });
  });
});

after(async () => {
  await browser.close();
});
