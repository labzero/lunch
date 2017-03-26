/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import { __RewireAPI__ as landingRewireApi } from './index';
import landing from './index';

const mockStore = configureStore();

describe('routes/landing', () => {
  let context;

  describe('when user has one role', () => {
    beforeEach(() => {
      landingRewireApi.__Rewire__('getTeams', () => [{
        slug: 'labzero'
      }]);
      context = {
        store: mockStore({
          user: {
            id: 1,
            roles: [{}],
          }
        })
      };
    });

    it('redirects user to team home', () => {
      expect(landing.action(context)).to.deep.eq({
        redirect: '/teams/labzero'
      });
    });
  });

  describe('when user has no roles', () => {
    beforeEach(() => {
      context = {
        store: mockStore({
          user: {
            id: 1,
            roles: [],
          }
        })
      };
    });

    it('redirects user to teams list', () => {
      expect(landing.action(context)).to.deep.eq({
        redirect: '/teams'
      });
    });
  });

  describe('when user has multiple roles', () => {
    beforeEach(() => {
      context = {
        store: mockStore({
          user: {
            id: 1,
            roles: [{}, {}, {}],
          }
        })
      };
    });

    it('redirects user to teams list', () => {
      expect(landing.action(context)).to.deep.eq({
        redirect: '/teams'
      });
    });
  });

  describe('when there is no user', () => {
    beforeEach(() => {
      context = {
        store: mockStore({
          user: {}
        })
      };
    });

    it('renders landing page', () => {
      expect(landing.action(context)).to.have.keys('component');
    });
  });
});
