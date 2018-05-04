/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as helpers from './helpers';
import singletons from './singletons';

describe('teams page (no teams)', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await helpers.login();
  }); 

  after(async () => {
    await helpers.logout();
  });

  it('shows that there are no teams', async () => {
    const res = await page.goto('http://local.lunch.pink:3000/teams');
      // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
  console.log("*******************\n" + res + "\n");
    await page.waitForSelector('.Teams-centerer .btn-default', helpers.waitOptions);
    const content = await page.content();
    expect(content).to.contain('You’re not currently a part of any teams!');
  });

  it('takes user to create team page', async () => {
    const res = await page.goto('http://local.lunch.pink:3000/teams');
      // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
  console.log("*******************\n" + res + "\n");
    await page.waitForSelector('.Teams-centerer .btn-default', helpers.waitOptions);
    await page.click('.btn-default');
    await page.waitForSelector('input', helpers.waitOptions);
    const content = await page.content();
    expect(content).to.contain('Create a new team');
    expect(content).to.contain('form-group');
  });

  describe('new team page', () => {
    it('has a new team form', async () => {
      const res = await page.goto('http://local.lunch.pink:3000/new-team');
        // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
  console.log("*******************\n" + res + "\n");
      await page.waitForSelector('#app', helpers.waitOptions);
      const content = await page.content();
      expect(content).to.contain('Create a new team');
      expect(content).to.contain('form-group');
    });

    it('creates a new team successfully', async () => {
      await helpers.createTeam();
      const content = await page.content();
      expect(content).to.contain('Visit one of your teams');
      expect(content).to.contain('list-group-item');
      await helpers.deleteTeam();
    });

    it('deletes a team successfully', async () => {
      await helpers.createTeam();
      await helpers.deleteTeam();
      const content = await page.content();
      expect(content).to.contain('You’re not currently a part of any teams!');
      expect(content).to.contain('Create a new team');
    });
  });
});
