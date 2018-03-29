/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as helpers from './helpers';
import singletons from './singletons';

describe('landing page', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await page.goto('http://local.lunch.pink:3000/');
    await page.waitForSelector('#app', helpers.waitOptions);
  });

  it('contains hero text', async () => {
    const content = await page.content();
    expect(content).to.contain('Figure it out');
  });

  it('has login link', async () => {
  	const content = await page.content();
    expect(content).to.contain('/login');
  });
});
