/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as decisions from '../decisions';
import { __RewireAPI__ as decisionsRewireAPI } from '../decisions';
import actionCreatorStub from '../../../test/actionCreatorStub';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/decisions', () => {
  let store;
  let teamSlug;
  let flashErrorStub;

  beforeEach(() => {
    store = mockStore({});
    teamSlug = 'labzero';
    flashErrorStub = actionCreatorStub();
    decisionsRewireAPI.__Rewire__('flashError', flashErrorStub);
  });

  describe('fetchDecision', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestDecision', () => {
        const requestDecisionStub = actionCreatorStub();
        decisionsRewireAPI.__Rewire__('requestDecision', requestDecisionStub);

        store.dispatch(decisions.fetchDecision(teamSlug));

        expect(requestDecisionStub.calledWith(teamSlug)).to.be.true;
      });

      it('fetches decision', () => {
        store.dispatch(decisions.fetchDecision(teamSlug));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/decisions/fromToday`);
      });
    });

    describe('success', () => {
      let receiveDecisionStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
        receiveDecisionStub = actionCreatorStub();
        decisionsRewireAPI.__Rewire__('receiveDecision', receiveDecisionStub);
        return store.dispatch(decisions.fetchDecision(teamSlug));
      });

      it('dispatches receiveDecision', () => {
        expect(receiveDecisionStub.calledWith({ foo: 'bar' }, teamSlug)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(decisions.fetchDecision(teamSlug));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('decide', () => {
    let restaurantId;

    beforeEach(() => {
      restaurantId = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postDecision', () => {
        const postDecisionStub = actionCreatorStub();
        decisionsRewireAPI.__Rewire__('postDecision', postDecisionStub);

        store.dispatch(decisions.decide(teamSlug, restaurantId));

        expect(postDecisionStub.calledWith(teamSlug, restaurantId)).to.be.true;
      });

      it('fetches decision', () => {
        store.dispatch(decisions.decide(teamSlug, restaurantId));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/decisions`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ restaurant_id: 1 }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(decisions.decide(teamSlug, restaurantId));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('removeDecision', () => {
    let restaurantId;
    beforeEach(() => {
      restaurantId = 1;
      decisionsRewireAPI.__Rewire__('getDecision', () => ({
        restaurant_id: restaurantId
      }));
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteDecision', () => {
        const deleteDecisionStub = actionCreatorStub();
        decisionsRewireAPI.__Rewire__('deleteDecision', deleteDecisionStub);

        store.dispatch(decisions.removeDecision(teamSlug));

        expect(deleteDecisionStub.calledWith(teamSlug, restaurantId)).to.be.true;
      });

      it('fetches decision', () => {
        store.dispatch(decisions.removeDecision(teamSlug));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/decisions/fromToday`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ restaurant_id: 1 }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(decisions.removeDecision(teamSlug));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });
});
