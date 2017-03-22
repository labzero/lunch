/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as decisions from '../decisions';
import ActionTypes from '../../constants/ActionTypes';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/decisions', () => {
  let store;
  let teamSlug;

  beforeEach(() => {
    store = mockStore({});
    teamSlug = 'labzero';
  });

  describe('fetchDecision', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestDecision', () => {
        store.dispatch(decisions.fetchDecision(teamSlug));

        expect(store.getActions()[0].type).to.eq(ActionTypes.REQUEST_DECISION);
      });

      it('fetches decision', () => {
        store.dispatch(decisions.fetchDecision(teamSlug));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/decisions/fromToday`);
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
        return store.dispatch(decisions.fetchDecision(teamSlug));
      });

      it('dispatches receiveDecision', () => {
        expect(store.getActions()[1]).to.deep.eq({
          type: ActionTypes.RECEIVE_DECISION,
          inst: { foo: 'bar' },
          teamSlug
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(decisions.fetchDecision(teamSlug));
      });

      it('dispatches flashError', () => {
        expect(store.getActions()[1].type).to.eq(ActionTypes.FLASH_ERROR);
      });
    });
  });
});
