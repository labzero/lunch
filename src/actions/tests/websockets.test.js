/* eslint-env mocha */

import { expect } from 'chai';
import { useFakeTimers } from 'sinon';
import configureStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import proxyquire from 'proxyquire';
import * as websockets from '../websockets';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/websockets', () => {
  let store;

  beforeEach(() => {
    store = mockStore({});
  });

  describe('messageReceived', () => {
    it('dispatches data if action is undefined', () => {
      const payload = '{ "type": "bar" }';
      store.dispatch(websockets.messageReceived(payload));
      const actions = store.getActions();
      expect(actions[0].type).to.eq('bar');
    });

    it('dispatches action with data if action type is given', () => {
      const payload = '{"type": "RESTAURANT_POSTED"}';
      const proxysockets = proxyquire('../websockets', {
        './restaurants': {
          sortRestaurants: () => ({
            type: 'SORT_RESTAURANTS'
          })
        }
      });
      const clock = useFakeTimers();
      store.dispatch(proxysockets.messageReceived(payload));
      clock.tick(1000);

      const actions = store.getActions();
      expect(actions[0].type).to.eq('RESTAURANT_POSTED');
      expect(actions[1].type).to.eq('NOTIFY');
      expect(actions[2].type).to.eq('SORT_RESTAURANTS');
      clock.restore();
    });
  });
});
