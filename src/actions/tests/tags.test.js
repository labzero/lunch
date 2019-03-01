/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates, arrow-body-style */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as tags from '../tags';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/tags', () => {
  let store;

  beforeEach(() => {
    store = mockStore({
      user: {
        id: 1
      }
    });
  });

  describe('fetchTags', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestTags', () => {
        return store.dispatch(tags.fetchTags()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('REQUEST_TAGS');
        });
      });

      it('fetches tags', () => {
        store.dispatch(tags.fetchTags());
        expect(fetchMock.lastCall()[0]).to.eq('/api/tags');
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
      });

      it('dispatches receiveTags', () => {
        return store.dispatch(tags.fetchTags()).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('RECEIVE_TAGS');
          expect(actions[1].items).to.eql([{ foo: 'bar' }]);
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(tags.fetchTags()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });

  describe('removeTag', () => {
    let id;
    beforeEach(() => {
      id = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteTag', () => {
        return store.dispatch(tags.removeTag(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('DELETE_TAG');
          expect(actions[0].id).to.eq(1);
        });
      });

      it('fetches restaurant', () => {
        store.dispatch(tags.removeTag(id));
        expect(fetchMock.lastCall()[0]).to.eq(`/api/tags/${id}`);
      });
    });

    describe('success', () => {
      beforeEach(() => {
        store = mockStore({
          user: {
            id: 1
          }
        });
        fetchMock.mock('*', {});
      });

      it('dispatches tagDeleted', () => {
        return store.dispatch(tags.removeTag(id)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('TAG_DELETED');
          expect(actions[1].id).to.eq(1);
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(tags.removeTag(id)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });
});
