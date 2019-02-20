/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates, arrow-body-style */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as decisions from '../decisions';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/decisions', () => {
  let store;

  beforeEach(() => {
    store = mockStore({});
  });

  describe('fetchDecisions', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestDecisions', () => {
        return store.dispatch(decisions.fetchDecisions()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('REQUEST_DECISIONS');
        });
      });

      it('fetches all the decisions', () => {
        store.dispatch(decisions.fetchDecisions());
        expect(fetchMock.lastCall()[0]).to.eq('/api/decisions/');
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
      });

      it('dispatches receiveDecision', () => {
        return store.dispatch(decisions.fetchDecisions()).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('RECEIVE_DECISIONS');
          expect(actions[1].items).to.eql([{ foo: 'bar' }]);
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(decisions.fetchDecisions()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
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
        return store.dispatch(decisions.decide(restaurantId)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('POST_DECISION');
          expect(actions[0].restaurantId).to.eq(1);
        });
      });

      it('fetches decision', () => {
        store.dispatch(decisions.decide(restaurantId));

        expect(fetchMock.lastCall()[0]).to.eq('/api/decisions');
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ restaurant_id: 1 }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(decisions.decide(restaurantId)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });

  describe('removeDecision', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteDecision', () => {
        return store.dispatch(decisions.removeDecision()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('DELETE_DECISION');
        });
      });

      it('fetches decision', () => {
        store.dispatch(decisions.removeDecision());

        expect(fetchMock.lastCall()[0]).to.eq('/api/decisions/fromToday');
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(decisions.removeDecision()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });
});
