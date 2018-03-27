/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as account from './helpers/account';
import singletons from './singletons';

describe('teams page (no teams)', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await account.login();
  }); 

  after(async () => {
    await account.logout();
  });

  it('shows that there are no teams', async () => {
    await page.goto('http://local.lunch.pink:3000/teams');
    await page.waitForSelector('.Teams-centerer .btn-default');
    const content = await page.content();
    expect(content).to.contain('You’re not currently a part of any teams!');
  });

  it('takes user to create team page', async () => {
    await page.goto('http://local.lunch.pink:3000/teams');
    await page.waitForSelector('.Teams-centerer .btn-default');
    await page.click('.btn-default');
    await page.waitForSelector('input');
    const content = await page.content();
    expect(content).to.contain('Create a new team');
    expect(content).to.contain('form-group');
  });

  describe('new team page', () => {
    it('has a new team form', async () => {
      await page.goto('http://local.lunch.pink:3000/new-team');
      await page.waitForSelector('#app');
      const content = await page.content();
      expect(content).to.contain('Create a new team');
      expect(content).to.contain('form-group');
    });

    it('creates a new team successfully', async () => {
      await account.createTeam();
      const content = await page.content();
      expect(content).to.contain('Visit one of your teams');
      expect(content).to.contain('list-group-item');
    });

    it('deletes a team successfully', async () => {
      await account.deleteTeam();
      const content = await page.content();
      expect(content).to.contain('You’re not currently a part of any teams!');
      expect(content).to.contain('Create a new team');
    });
  });
});
