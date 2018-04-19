/* eslint-env mocha */
/* eslint-disable no-multi-assign */

import Bluebird from 'bluebird';
import puppeteer from 'puppeteer';
import singletons from './integration/singletons';

// use bluebird instead of native promises for improved async stack traces
Bluebird.config({ longStackTraces: true });
global.Promise = Bluebird;

let browser;

const loadPage = () => new Promise((resolve, reject) => {
  let tryCount = 0;
  const innerLoadPage = async () => {
    try {
      await singletons.page.goto('http://local.lunch.pink:3000/');
      resolve();
    } catch (err) {
      if (err.message.indexOf('ERR_CONNECTION_REFUSED') > -1 && tryCount < 30) {
        // eslint-disable-next-line no-console
        console.log('No response from server. Trying again in 1 second...');
        setTimeout(innerLoadPage, 1000);
        tryCount += 1;
      } else {
        reject(err);
      }
    };
  };
  innerLoadPage();
});

const opts =
  {
    headless: !!process.env.CI,
    slowMo: 35,
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

afterEach(async function() {
  if (this.currentTest.state === 'failed') {
    const title = this.currentTest.title.replace(/ /g,"_");
    await singletons.page.screenshot({path: `screenshots/${title}.png`});
  }
});
