/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import { spy } from 'sinon';
import proxyquire from 'proxyquire';
import mockEsmodule from '../../../../test/mockEsmodule';

const proxyquireStrict = proxyquire.noCallThru();
const mockStore = configureStore();

describe('routes/helpers/renderIfHasName', () => {
  let makeRouteSpy;
  let context;

  beforeEach(() => {
    makeRouteSpy = spy();
  });

  describe('when there is no user', () => {
    let redirectToLoginSpy;
    let renderIfHasNameProxy;
    beforeEach(() => {
      redirectToLoginSpy = spy();
      renderIfHasNameProxy = proxyquireStrict('../renderIfHasName', {
        './redirectToLogin': mockEsmodule({
          default: redirectToLoginSpy
        })
      }).default;
      context = {
        store: mockStore({
          user: {}
        })
      };
      renderIfHasNameProxy(context, makeRouteSpy);
    });

    it('redirects to login', () => {
      expect(redirectToLoginSpy.calledWith(context)).to.be.true;
    });
  });
});
