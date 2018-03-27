/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as account from './helpers/account';
import singletons from './singletons';

describe('Adding a restaurant and tag', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await account.login();
    await account.createTeam();
  }); 

  beforeEach(async () => {    
    await page.goto('http://integration-test.local.lunch.pink:3000/');
    await page.waitForSelector('#app');
  });

  after(async () => {
    await account.deleteTeam();
    await account.logout();
  });

  describe('landing page (logged in)', () => {

    it('loads the map and geosuggest input field', async () => {
      const content = await page.content();
      expect(content).to.contain('https://maps.googleapis.com/maps/vt?');
      expect(content).to.contain('geosuggest__input');
      expect(content).to.contain('placeholder="Add places"');
    });

    describe('with no restaurants', () => {

      it('shows the Welcome box', async () => {
        await page.waitForSelector('.RestaurantList-welcome');
        const content = await page.content();
        expect(content).to.contain('Welcome to Lunch!');
      });

    });

    describe('Adding a restaurant', () => {

      it('makes suggestions and then displays the new restaurant in the restaurant list', async () => {
        await account.addRestaurant();
        const content = await page.content();
        expect(content).to.contain('filter by name');
        expect(content).to.contain('Restaurant-root');
        await account.deleteRestaurant();
      });

      it('show the restaurant list item with contents', async () => {
        await account.addRestaurant();
        const content = await page.content();
        expect(content).to.contain('Restaurant-data');
        expect(content).to.contain('Restaurant-heading');
        expect(content).to.contain('Restaurant-addressContainer');
        expect(content).to.contain('Restaurant-voteContainer');
        expect(content).to.contain('Restaurant-footer');
        await account.deleteRestaurant();
      });

      it('deletes a restaurant successfully', async () => {
        await account.addRestaurant();
        await account.deleteRestaurant();
        const content = await page.content();
        expect(content).to.contain('Welcome to Lunch!');
      });
    });

    describe('Adding a tag', () => {

      it('shows the three filter buttons after adding a tag', async () => {
        await account.addRestaurant();
        await account.addTag();
        const content = await page.content();
        expect(content).to.contain('filter by tag');
        expect(content).to.contain('exclude tags');
        expect(content).to.contain('waterfront');
        await account.deleteTag();
        await account.deleteRestaurant();
      });

      it('deletes a tag successfully', async () => {
        await account.addRestaurant();
        await account.addTag();
        await account.deleteTag();
        const content = await page.content();
        expect(content).to.not.contain('waterfront');
        await account.deleteRestaurant();
      });
    });
  });
});
