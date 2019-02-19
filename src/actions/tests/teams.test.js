/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates, arrow-body-style */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as teams from '../teams';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/teams', () => {
  let store;

  beforeEach(() => {
    store = mockStore({});
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
        return store.dispatch(teams.createTeam(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq('POST_TEAM');
          expect(actions[0].team).to.eql({ foo: 'bar' });
        });
      });

      it('fetches restaurant', () => {
        store.dispatch(teams.createTeam(payload));

        expect(fetchMock.lastCall()[0]).to.eq('/api/teams');
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify(payload));
      });
    });

    describe('success', () => {
      let team;
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
      });

      it('dispatches teamPosted', () => {
        return store.dispatch(teams.createTeam(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('TEAM_POSTED');
          expect(actions[1].team).to.eql(team);
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
      });

      it('dispatches flashError', () => {
        return store.dispatch(teams.createTeam(payload)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq('FLASH_ERROR');
        });
      });
    });
  });
});
