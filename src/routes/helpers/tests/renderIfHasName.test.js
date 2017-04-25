/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import { spy } from 'sinon';
import { __RewireAPI__ as rewireApi } from '../renderIfHasName';
import renderIfHasName from '../renderIfHasName';

const mockStore = configureStore();

describe('routes/helpers/renderIfHasName', () => {
  let makeRouteSpy;
  let context;

  beforeEach(() => {
    makeRouteSpy = spy();
  });

  describe('when there is no user', () => {
    let redirectToLoginSpy;
    beforeEach(() => {
      redirectToLoginSpy = spy();
      rewireApi.__Rewire__('redirectToLogin', redirectToLoginSpy);
      context = {
        store: mockStore({
          user: {}
        })
      };
      renderIfHasName(context, makeRouteSpy);
    });

    it('redirects to login', () => {
      expect(redirectToLoginSpy.calledWith(context)).to.be.true;
    });
  });
});
