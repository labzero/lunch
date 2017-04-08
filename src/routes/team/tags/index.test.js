/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import { spy } from 'sinon';
import configureStore from 'redux-mock-store';
import { __RewireAPI__ as landingRewireApi } from './index';
import landing from './index';

const mockStore = configureStore();

describe('routes/teams/team/tags', () => {
  let context;
  let render404;

  beforeEach(() => {
    context = {
      params: {},
      store: mockStore({
        user: {
          id: 1
        }
      })
    };
    landingRewireApi.__Rewire__('getTeam', () => [{
      id: 77
    }]);
  });

  describe('when user is not on team', () => {
    let result;
    beforeEach((done) => {
      render404 = 'render404';
      landingRewireApi.__Rewire__('render404', render404);
      landingRewireApi.__Rewire__('hasRole', () => false);
      landing.action(context).then(r => {
        result = r;
        done();
      });
    });

    it('renders 404', () => {
      expect(result).to.eq(render404);
    });
  });

  describe('when user is on team', () => {
    let result;
    beforeEach((done) => {
      landingRewireApi.__Rewire__('hasRole', () => true);
      landing.action(context).then(r => {
        result = r;
        done();
      });
    });

    it('renders team', () => {
      expect(result).to.have.keys('component', 'chunk', 'title');
    });
  });

  describe('when there is no user', () => {
    let redirectToLoginSpy;
    beforeEach(() => {
      redirectToLoginSpy = spy();
      landingRewireApi.__Rewire__('redirectToLogin', redirectToLoginSpy);
      context.store = mockStore({
        user: {}
      });
      return landing.action(context);
    });

    it('redirects to login', () => {
      expect(redirectToLoginSpy.calledWith(context)).to.be.true;
    });
  });
});
