/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as helpers from './helpers';
import singletons from './singletons';

describe('login page', () => {
  let browser;
  let page;

  before(() => {
    browser = singletons.browser;
    page = singletons.page;
  });

  beforeEach(async () => {
    await page.goto('http://local.lunch.pink:3000/login');
    await page.waitForSelector('#app');
  });

  it('contains email and password fields', async () => {
    const content = await page.content();
    expect(content).to.contain('Email/password');
  });

  it('has an option to log in with google', async () => {
    const content = await page.content();
    expect(content).to.contain('Sign in with Google');
  });

  it('has forgot password link', async () => {
  	const content = await page.content();
    expect(content).to.contain('Forgot password?');
  });

  it('logs in successfully', async () => {
    await helpers.login();
    const content = await page.content();
    expect(content).to.contain('You’re not currently a part of any teams!');
    await helpers.logout();
  });
});