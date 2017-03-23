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
  let teamSlug;
  let flashErrorStub;

  beforeEach(() => {
    store = mockStore({});
    teamSlug = 'labzero';
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

        store.dispatch(users.fetchUsers(teamSlug));

        expect(requestUsersStub.calledWith(teamSlug)).to.be.true;
      });

      it('fetches users', () => {
        store.dispatch(users.fetchUsers(teamSlug));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/users`);
      });
    });

    describe('success', () => {
      let receiveUsersStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
        receiveUsersStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('receiveUsers', receiveUsersStub);
        return store.dispatch(users.fetchUsers(teamSlug));
      });

      it('dispatches receiveUsers', () => {
        expect(receiveUsersStub.calledWith([{ foo: 'bar' }], teamSlug)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(users.fetchUsers(teamSlug));
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

        store.dispatch(users.addUser(teamSlug, payload));

        expect(postUserStub.calledWith(teamSlug, payload)).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(users.addUser(teamSlug, payload));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/users`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify(payload));
      });
    });

    describe('success', () => {
      let userPostedStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: { foo: 'bar' } });
        userPostedStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('userPosted', userPostedStub);
        return store.dispatch(users.addUser(teamSlug, payload));
      });

      it('dispatches userPosted', () => {
        expect(userPostedStub.calledWith({ foo: 'bar' }, teamSlug)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          users.addUser(teamSlug, payload)
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
      id = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteUser', () => {
        const deleteUserStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('deleteUser', deleteUserStub);

        store.dispatch(users.removeUser(teamSlug, id));

        expect(deleteUserStub.calledWith(teamSlug, id)).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(users.removeUser(teamSlug, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/users/${id}`);
      });
    });

    describe('success', () => {
      let userDeletedStub;
      beforeEach(() => {
        fetchMock.mock('*', {});
        userDeletedStub = actionCreatorStub();
        usersRewireAPI.__Rewire__('userDeleted', userDeletedStub);
        return store.dispatch(users.removeUser(teamSlug, id));
      });

      it('dispatches userDeleted', () => {
        expect(userDeletedStub.calledWith(id, teamSlug)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(users.removeUser(teamSlug, id));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });
});
