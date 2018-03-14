/* eslint-env mocha */

const puppeteer = require('puppeteer');
const { expect } = require('chai');

let browser;
let page;

before((done) => {
  puppeteer.launch({
    headless: false,
  }).then((b) => {
    browser = b;
    browser.newPage().then((p) => {
      page = p;
      let gotoInterval = setInterval(() => {
        page.goto('http://local.lunch.pink:3000').then(() => {
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

describe('landing page', () => {
  it('contains hero text', (done) => {
    page.content().then((content) => {
      expect(content).to.contain('Figure it out');
      done();
    });
  });
  it('has login link', (done) => {
  	page.content().then((content) => {
      expect(content).to.contain('/login');
      done();
    });
  })
});
