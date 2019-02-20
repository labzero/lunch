/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates, arrow-body-style */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import proxyquire from 'proxyquire';
import thunk from 'redux-thunk';
import * as users from '../users';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/users', () => {
  let store;

  beforeEach(() => {
    store = mockStore({});
  });

  describe('fetchUsers', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestUsers', () => {
        return store.dispatch(users.fetchUsers()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('REQUEST_USERS');
        });
      });

      it('fetches users', () => {
        store.dispatch(users.fetchUsers());

        expect(fetchMock.lastCall()[0]).to.eq('/api/users');
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
      });

      it('dispatches receiveUsers', () => {
        return store.dispatch(users.fetchUsers()).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('RECEIVE_USERS');
          expect(actions[1].items).to.eql([{ foo: 'bar' }]);
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(users.fetchUsers()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });

  describe('addUser', () => {
    let payload;

    beforeEach(() => {
      payload = { foo: 'bar' };
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postUser', () => {
        return store.dispatch(users.addUser(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('POST_USER');
          expect(actions[0].user).to.eql({ foo: 'bar' });
        });
      });

      it('fetches restaurant', () => {
        store.dispatch(users.addUser(payload));

        expect(fetchMock.lastCall()[0]).to.eq('/api/users');
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify(payload));
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
      });

      it('dispatches userPosted', () => {
        return store.dispatch(users.addUser(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('USER_POSTED');
          expect(actions[1].user).to.eql({ foo: 'bar' });
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(
          users.addUser(payload)
        ).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });

  describe('removeUser', () => {
    let id;
    let proxyUsers;
    beforeEach(() => {
      id = 1;
      proxyUsers = proxyquire('../users', {
        '../selectors/user': {
          getCurrentUser: () => {
            return { id: 231 };
          }
        }
      });
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteUser', () => {
        return store.dispatch(proxyUsers.removeUser(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('DELETE_USER');
          expect(actions[0].id).to.eq(1);
        });
      });

      it('fetches user', () => {
        store.dispatch(proxyUsers.removeUser(id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/users/${id}`);
      });
    });

    describe('when id is of current user', () => {
      beforeEach(() => {
        id = 231;
        fetchMock.mock('*', {});
      });

      it('dispatches deleteUser with isSelf = true', () => {
        return store.dispatch(proxyUsers.removeUser(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('DELETE_USER');
          expect(actions[0].isSelf).to.eq(true);
          expect(actions[0].id).to.eq(231);
          expect(actions[0].team).to.eq(undefined);
        });
      });
    });

    describe('when team is provided', () => {
      let team;
      beforeEach(() => {
        store = mockStore({
          host: 'lunch.pink'
        });
        team = {
          slug: 'labzero'
        };
        fetchMock.mock('*', {});
      });

      it('dispatches deleteUser with team', () => {
        return store.dispatch(proxyUsers.removeUser(id, team)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('DELETE_USER');
          expect(actions[0].team).to.eql({ slug: 'labzero' });
          expect(actions[0].id).to.eq(1);
        });
      });

      it('fetches user with full url', () => {
        store.dispatch(proxyUsers.removeUser(id, team));
        expect(fetchMock.lastCall()[0]).to.eq(`//${team.slug}.lunch.pink/api/users/${id}`);
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches userDeleted', () => {
        return store.dispatch(proxyUsers.removeUser(id)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('USER_DELETED');
          expect(actions[1].id).to.eq(1);
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(proxyUsers.removeUser(id)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });

  describe('changeUserRole', () => {
    let id;
    let roleType;
    let proxyUsers;
    beforeEach(() => {
      id = 1;
      roleType = 'member';
      proxyUsers = proxyquire('../users', {
        '../selectors/user': {
          getCurrentUser: () => {
            return { id: 231 };
          }
        }
      });
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches patchUser', () => {
        return store.dispatch(proxyUsers.changeUserRole(id, roleType)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('PATCH_USER');
          expect(actions[0].id).to.eq(1);
          expect(actions[0].roleType).to.eq('member');
        });
      });

      it('fetches user', () => {
        store.dispatch(proxyUsers.changeUserRole(id, roleType));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/users/${id}`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ id, type: roleType }));
      });
    });

    describe('success', () => {
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
      });

      it('dispatches userPatched', () => {
        return store.dispatch(proxyUsers.changeUserRole(id, roleType)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('USER_PATCHED');
          expect(actions[1].id).to.eq(1);
          expect(actions[1].user).to.eql({ foo: 'bar' });
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(proxyUsers.changeUserRole(id, roleType)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });
});
