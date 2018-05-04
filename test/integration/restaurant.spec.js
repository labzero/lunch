/* eslint-env mocha */
/* eslint-disable no-unused-vars */

import puppeteer from 'puppeteer';
import { expect } from 'chai';

import * as helpers from './helpers';
import singletons from './singletons';

describe('Adding a restaurant and tag', () => {
  let browser;
  let page;

  before(async () => {
    browser = singletons.browser;
    page = singletons.page;
    await helpers.login();
    await helpers.createTeam();
  }); 

  beforeEach(async () => {    
    const res = await page.goto('http://integration-test.local.lunch.pink:3000/');
      // eslint-disable-next-line no-console, no-unused-expressions, prefer-template
  console.log("*******************\n" + res + "\n");
    await page.waitForSelector('#app', helpers.waitOptions);
  });

  after(async () => {
    await helpers.deleteTeam();
    await helpers.logout();
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
        await page.waitForSelector('.RestaurantList-welcome', helpers.waitOptions);
        const content = await page.content();
        expect(content).to.contain('Welcome to Lunch!');
      });

    });

    describe('Adding a restaurant', () => {
      beforeEach(async () => {
        await helpers.addRestaurant();
      });

      it('makes suggestions and then displays the new restaurant in the restaurant list', async () => {
        const content = await page.content();
        expect(content).to.contain('filter by name');
        expect(content).to.contain('Restaurant-root');
        await helpers.deleteRestaurant();
      });

      it('show the restaurant list item with contents', async () => {
        const content = await page.content();
        expect(content).to.contain('Restaurant-data');
        expect(content).to.contain('Restaurant-heading');
        expect(content).to.contain('Restaurant-addressContainer');
        expect(content).to.contain('Restaurant-voteContainer');
        expect(content).to.contain('Restaurant-footer');
        await helpers.deleteRestaurant();
      });

      it('deletes a restaurant successfully', async () => {
        await helpers.deleteRestaurant();
        const content = await page.content();
        expect(content).to.contain('Welcome to Lunch!');
      });
    });

    describe('Adding a tag', () => {
      beforeEach(async () => {
        await helpers.addRestaurant();
        await helpers.addTag();
      });

      afterEach(async () => {
        await helpers.deleteRestaurant()
      });

      it('shows the three filter buttons after adding a tag', async () => {
        const content = await page.content();
        expect(content).to.contain('filter by tag');
        expect(content).to.contain('exclude tags');
        expect(content).to.contain('waterfront');
        await helpers.deleteTag();
      });

      it('deletes a tag successfully', async () => {
        await helpers.deleteTag();
        const content = await page.content();
        expect(content).to.not.contain('waterfront');
      });
    });
  });
});
