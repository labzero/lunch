/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import { spy } from 'sinon';
import { __RewireAPI__ as rewireApi } from '../renderIfLoggedOut';
import renderIfLoggedOut from '../renderIfLoggedOut';

describe('routes/helpers/renderIfLoggedOut', () => {
  let makeRouteSpy;
  let state;

  beforeEach(() => {
    makeRouteSpy = spy();
  });

  describe('when user has one role', () => {
    beforeEach(() => {
      rewireApi.__Rewire__('getTeams', () => [{
        slug: 'labzero'
      }]);
      state = {
        host: 'lunch.pink',
        user: {
          id: 1,
          roles: [{}],
        }
      };
    });

    it('redirects user to team home', () => {
      expect(renderIfLoggedOut(state, makeRouteSpy)).to.deep.eq({
        redirect: '//labzero.lunch.pink'
      });
    });
  });

  describe('when user has no roles', () => {
    beforeEach(() => {
      state = {
        user: {
          id: 1,
          roles: [],
        }
      };
    });

    it('redirects user to teams list', () => {
      expect(renderIfLoggedOut(state, makeRouteSpy)).to.deep.eq({
        redirect: '/teams'
      });
    });
  });

  describe('when user has multiple roles', () => {
    beforeEach(() => {
      state = {
        user: {
          id: 1,
          roles: [{}, {}, {}],
        }
      };
    });

    it('redirects user to teams list', () => {
      expect(renderIfLoggedOut(state, makeRouteSpy)).to.deep.eq({
        redirect: '/teams'
      });
    });
  });

  describe('when there is no user', () => {
    beforeEach(() => {
      state = {
        user: {}
      };
      renderIfLoggedOut(state, makeRouteSpy);
    });

    it('renders landing page', () => {
      expect(makeRouteSpy.callCount).to.eq(1);
    });
  });
});
