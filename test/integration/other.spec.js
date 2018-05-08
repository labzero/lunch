/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as helpers from './helpers';
import singletons from './singletons';

describe('other pages', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await helpers.login();
    await helpers.createTeam();
  }); 

  after(async () => {
    await helpers.deleteTeam();
    await helpers.logout();
  });

  describe('hamburger menu', () => {
    it('expands to show menu contents', async () => {
      await page.goto('http://local.lunch.pink:3000/');
      await page.click('#header button');
      // todo: check that menu expands (both the button overlay and nav menu have no class)
      const content = await page.content();
      expect(content).to.contain('/team');
      expect(content).to.contain('/tags');
      expect(content).to.contain('//local.lunch.pink:3000/teams');
      expect(content).to.contain('//local.lunch.pink:3000/account');
      expect(content).to.contain('//local.lunch.pink:3000/logout');
    });
  });

  describe('Account page', () => {
    it('should have "Name," "Email," and "Change Password?" inputs and Submit button', async () => {
      await page.goto('http://local.lunch.pink:3000/account');
      await page.waitForSelector('.form-group', helpers.waitOptions);
      const content = await page.content();
      expect(content).to.contain('Name');
      expect(content).to.contain('Email');
      expect(content).to.contain('Change password?');
      expect(content).to.contain('Submit');
    });
  });

  describe('Tags page', () => {
    it('should display blurb when no tags', async () => {
      await page.goto('http://integration-test.local.lunch.pink:3000/tags');
      await page.waitForSelector('#app', helpers.waitOptions);
      const content = await page.content();
      expect(content).to.contain('Once you add tags');
    });

    it('should display a list of tags when there are tags', async () => {
      await helpers.addRestaurant();
      await helpers.addTag();
      await page.goto('http://integration-test.local.lunch.pink:3000/tags');
      await page.waitForSelector('.Tag-button', helpers.waitOptions);
      const content = await page.content();
      expect(content).to.contain('waterfront');
      await helpers.deleteTag();
      await helpers.deleteRestaurant();
    });
  });

  describe('About page', () => {
    it('should have some content', async () => {
      await page.goto('http://local.lunch.pink:3000/about');
      await page.waitForSelector('#app', helpers.waitOptions);
      const content = await page.content();
      expect(content).to.contain('About Lunch');
    });
  });

  describe('404 page', () => {
    it('should have some content', async () => {
      await page.goto('http://local.lunch.pink:3000/404');
      await page.waitForSelector('#app', helpers.waitOptions);
      const content = await page.content();
      expect(content).to.contain('Page not found');
    });
  });
});
