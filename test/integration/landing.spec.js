// // eslint-disable

// const puppeteer = require('puppeteer');

// let browser;

// before(async () => {
//  browser = await puppeteer.launch({
//    headless: false,
//    slowMo: 250 // slow down by 250ms
//  });
//   const page = await browser.newPage();
//   await page.goto('https://local.lunch.pink:3000');
//   await page.screenshot({path: 'example.png'});

// });

// after(browser.close);

// it('returns true', () => true);

// /*

// use mocha to test pages

// */