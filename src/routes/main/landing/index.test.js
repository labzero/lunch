/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import { __RewireAPI__ as landingRewireApi } from './index';
import landing from './index';

const mockStore = configureStore();

describe('routes/landing', () => {
  let context;
  let route;

  describe('when user has one role', () => {
    beforeEach((done) => {
      landingRewireApi.__Rewire__('getTeams', () => [{
        slug: 'labzero'
      }]);
      context = {
        store: mockStore({
          host: 'lunch.pink',
          user: {
            id: 1,
            roles: [{}],
          }
        })
      };

      landing.action(context).then((r) => {
        route = r;
        done();
      });
    });

    it('redirects user to team home', () => {
      expect(route).to.deep.eq({
        redirect: '//labzero.lunch.pink'
      });
    });
  });

  describe('when user has no roles', () => {
    beforeEach((done) => {
      context = {
        store: mockStore({
          user: {
            id: 1,
            roles: [],
          }
        })
      };

      landing.action(context).then((r) => {
        route = r;
        done();
      });
    });

    it('redirects user to teams list', () => {
      expect(route).to.deep.eq({
        redirect: '/teams'
      });
    });
  });

  describe('when user has multiple roles', () => {
    beforeEach((done) => {
      context = {
        store: mockStore({
          user: {
            id: 1,
            roles: [{}, {}, {}],
          }
        })
      };

      landing.action(context).then((r) => {
        route = r;
        done();
      });
    });

    it('redirects user to teams list', () => {
      expect(route).to.deep.eq({
        redirect: '/teams'
      });
    });
  });

  describe('when there is no user', () => {
    beforeEach((done) => {
      context = {
        store: mockStore({
          user: {}
        })
      };

      landing.action(context).then((r) => {
        route = r;
        done();
      });
    });

    it('renders landing page', () => {
      expect(route).to.have.keys('chunk', 'component');
    });
  });
});
