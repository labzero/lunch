/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as teams from '../teams';
import { __RewireAPI__ as teamsRewireAPI } from '../teams';
import actionCreatorStub from '../../../test/actionCreatorStub';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/teams', () => {
  let store;
  let flashErrorStub;

  beforeEach(() => {
    store = mockStore({});
    flashErrorStub = actionCreatorStub();
    teamsRewireAPI.__Rewire__('flashError', flashErrorStub);
  });

  describe('createTeam', () => {
    let payload;
    beforeEach(() => {
      payload = { foo: 'bar' };
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postTeam', () => {
        const postTeamStub = actionCreatorStub();
        teamsRewireAPI.__Rewire__('postTeam', postTeamStub);

        store.dispatch(teams.createTeam(payload));

        expect(postTeamStub.calledWith(payload)).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(teams.createTeam(payload));

        expect(fetchMock.lastCall()[0]).to.eq('/api/teams');
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify(payload));
      });
    });

    describe('success', () => {
      let team;
      let teamPostedStub;
      let userRoleAddedStub;
      beforeEach(() => {
        team = {
          foo: 'bar',
          roles: [{
            id: 1,
            team_id: 2,
            user_id: 3
          }]
        };
        fetchMock.mock('*', {
          data: team
        });
        teamPostedStub = actionCreatorStub();
        teamsRewireAPI.__Rewire__('teamPosted', teamPostedStub);
        userRoleAddedStub = actionCreatorStub();
        teamsRewireAPI.__Rewire__('userRoleAdded', userRoleAddedStub);
        return store.dispatch(teams.createTeam(payload));
      });

      it('dispatches teamPosted', () => {
        expect(teamPostedStub.calledWith(team)).to.be.true;
      });

      it('dispatches userRoleAdded', () => {
        expect(userRoleAddedStub.calledWith(team.roles[0])).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(teams.createTeam(payload)).catch(() => Promise.resolve());
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });
});
