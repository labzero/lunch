/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as account from './helpers/account';
import singletons from './singletons';

describe('team page (within team)', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await account.login();
    await account.createTeam();
  }); 

  after(async () => {
    await account.deleteTeam();
    await account.logout();
  });

  beforeEach(async () => {
    await page.goto('http://integration-test.local.lunch.pink:3000/team');
    await page.waitForSelector('.form-group');
  });

  describe('team page', () => {
    it('should have Users, Team, and Messy Business tabs (for team owner)', async () => {
      const content = await page.content();
      expect(content).to.contain('Users');
      expect(content).to.contain('Team');
      expect(content).to.contain('Messy Business');
      expect(content).to.contain('team-tabs-tab-1');
      expect(content).to.contain('team-tabs-tab-2');
      expect(content).to.contain('team-tabs-tab-3');
    });

    describe('under Users tab', () => {
      it('should have User List and Add User form', async () => {
        const content = await page.content();
        expect(content).to.contain('User List');
        expect(content).to.contain('Add User');
      });
    });

    describe('under Team tab', () => {
      it('should have Name input, Address section, Sort duration, and Save Changes button', async () => {
        await page.click('#team-tabs-tab-2');
        await page.waitForSelector('.gm-style');
        const content = await page.content();
        expect(content).to.contain('Name');
        expect(content).to.contain('Address');
        expect(content).to.contain('Sort duration');
        expect(content).to.contain('Save Changes');
      });
    });

    describe('under Messy Business tab', () => {
      it('should have Change team URL button and Delete team button', async () => {
        await page.click('#team-tabs-tab-3');
        await page.waitForSelector('.btn-danger');
        const content = await page.content();
        expect(content).to.contain('Change team URL');
        expect(content).to.contain('Delete team');
      });
    });
  });
});
