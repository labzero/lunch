/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import { __RewireAPI__ as landingRewireApi } from './index';
import landing from './index';

const mockStore = configureStore();

describe('routes/team/team', () => {
  let context;
  let render404;
  let team;

  beforeEach(() => {
    landingRewireApi.__Rewire__('renderIfHasName', (_, cb) => cb());
    team = {
      id: 77
    };
    context = {
      params: {},
      query: {},
      store: mockStore({
        team,
        user: {
          id: 1
        }
      })
    };
  });

  describe('when user is a guest', () => {
    let result;
    beforeEach(() => {
      render404 = 'render404';
      landingRewireApi.__Rewire__('render404', render404);
      landingRewireApi.__Rewire__('hasRole', () => false);
      result = landing(context);
    });

    it('renders 404', () => {
      expect(result).to.eq(render404);
    });
  });

  describe('when user is at least a member', () => {
    let result;
    beforeEach(() => {
      landingRewireApi.__Rewire__('hasRole', () => true);
      result = landing(context);
    });

    it('renders team', () => {
      expect(result).to.have.keys('component', 'chunks', 'map', 'title');
    });
  });
});
