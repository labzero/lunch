/* eslint-env mocha */
/* eslint-disable no-multi-assign */

import puppeteer from 'puppeteer';
import singletons from './integration/singletons';

let browser;

const loadPage = () => new Promise((resolve, reject) => {
  const innerLoadPage = async () => {
    try {
      await singletons.page.goto('http://local.lunch.pink:3000/');
      resolve();
    } catch (err) {
      if (err.message.indexOf('ERR_CONNECTION_REFUSED' > -1)) {
        // eslint-disable-next-line no-console
        console.log('No response from server. Trying again in 1 second...');
        setTimeout(innerLoadPage, 1000);
      } else {
        reject();
      }
    };
  };
  innerLoadPage();
});

const opts = process.env.CI ?
  {
    headless: true,
  } :
  { headless: false,
    slowMo: 10,
  };

before(async () => {
  browser = singletons.browser = await puppeteer.launch(opts);
  singletons.page = await browser.newPage();
  singletons.page.setViewport({width: 1024, height: 768});
  await loadPage();
});

after(async () => {
  await browser.close();
});
