/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as users from '../users';
import { __RewireAPI__ as usersRewireAPI } from '../users';
import actionCreatorStub from '../../../test/actionCreatorStub';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/users', () => {
  let store;
  let flashErrorStub;

  beforeEach(() => {
    store = mockStore({});
    flashErrorStub = actionCreatorStub();
    usersRewireAPI.__Rewire__('flashError', flashErrorStub);
  });

  describe('fetchUsers', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestUsers', () => {
        const requestUsersStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('requestUsers', requestUsersStub);

        store.dispatch(users.fetchUsers());

        expect(requestUsersStub.callCount).to.eq(1);
      });

      it('fetches users', () => {
        store.dispatch(users.fetchUsers());

        expect(fetchMock.lastCall()[0]).to.eq('/api/users');
      });
    });

    describe('success', () => {
      let receiveUsersStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
        receiveUsersStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('receiveUsers', receiveUsersStub);
        return store.dispatch(users.fetchUsers());
      });

      it('dispatches receiveUsers', () => {
        expect(receiveUsersStub.calledWith([{ foo: 'bar' }])).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(users.fetchUsers());
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
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
        const postUserStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('postUser', postUserStub);

        store.dispatch(users.addUser(payload));

        expect(postUserStub.calledWith(payload)).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(users.addUser(payload));

        expect(fetchMock.lastCall()[0]).to.eq('/api/users');
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify(payload));
      });
    });

    describe('success', () => {
      let userPostedStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
        userPostedStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('userPosted', userPostedStub);
        return store.dispatch(users.addUser(payload));
      });

      it('dispatches userPosted', () => {
        expect(userPostedStub.calledWith({ foo: 'bar' })).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          users.addUser(payload)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('removeUser', () => {
    let id;
    beforeEach(() => {
      usersRewireAPI.__Rewire__('getCurrentUser', () => ({
        id: 231
      }));
      id = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteUser', () => {
        const deleteUserStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('deleteUser', deleteUserStub);

        store.dispatch(users.removeUser(id));

        expect(deleteUserStub.calledWith(id)).to.be.true;
      });

      it('fetches user', () => {
        store.dispatch(users.removeUser(id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/users/${id}`);
      });
    });

    describe('when id is of current user', () => {
      let deleteUserStub;
      beforeEach(() => {
        id = 231;
        fetchMock.mock('*', {});
        deleteUserStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('deleteUser', deleteUserStub);

        store.dispatch(users.removeUser(id));
      });

      it('dispatches deleteUser with isSelf = true', () => {
        expect(deleteUserStub.calledWith(id, undefined, true)).to.be.true;
      });
    });

    describe('when team is provided', () => {
      let deleteUserStub;
      let team;
      beforeEach(() => {
        store = mockStore({
          host: 'lunch.pink'
        });
        team = {
          slug: 'labzero'
        };
        fetchMock.mock('*', {});
        deleteUserStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('deleteUser', deleteUserStub);
        store.dispatch(users.removeUser(id, team));
      });

      it('dispatches deleteUser with team', () => {
        expect(deleteUserStub.calledWith(id, team)).to.be.true;
      });

      it('fetches user with full url', () => {
        expect(fetchMock.lastCall()[0]).to.eq(`//${team.slug}.lunch.pink/api/users/${id}`);
      });
    });

    describe('success', () => {
      let userDeletedStub;
      beforeEach(() => {
        fetchMock.mock('*', {});
        userDeletedStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('userDeleted', userDeletedStub);
        return store.dispatch(users.removeUser(id));
      });

      it('dispatches userDeleted', () => {
        expect(userDeletedStub.calledWith(id)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(users.removeUser(id));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('changeUserRole', () => {
    let id;
    let roleType;
    beforeEach(() => {
      id = 1;
      roleType = 'member';
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches patchUser', () => {
        const patchUserStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('patchUser', patchUserStub);

        store.dispatch(users.changeUserRole(id, roleType));

        expect(patchUserStub.calledWith(id, roleType)).to.be.true;
      });

      it('fetches user', () => {
        store.dispatch(users.changeUserRole(id, roleType));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/users/${id}`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ id, type: roleType }));
      });
    });

    describe('success', () => {
      let userPatchedStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
        userPatchedStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('userPatched', userPatchedStub);
        return store.dispatch(users.changeUserRole(id, roleType));
      });

      it('dispatches userPatched', () => {
        expect(userPatchedStub.calledWith(id, { foo: 'bar' })).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(users.changeUserRole(id, roleType));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });
});
