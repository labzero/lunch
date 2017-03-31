/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import ActionTypes from '../../constants/ActionTypes';
import users from '../user';

describe('reducerMaps/user', () => {
  describe('TEAM_POSTED', () => {
    let beforeState;
    let afterState;
    beforeEach(() => {
      beforeState = {
        id: 1,
        roles: []
      };
    });

    describe('when role is on different user', () => {
      beforeEach(() => {
        afterState = users.get(ActionTypes.TEAM_POSTED)(beforeState, {
          team: {
            roles: [{
              user_id: 2,
              type: 'owner'
            }]
          }
        });
      });

      it('does not modify state', () => {
        expect(afterState).to.eq(beforeState);
      });
    });

    describe('when role is on logged-in user', () => {
      beforeEach(() => {
        afterState = users.get(ActionTypes.TEAM_POSTED)(beforeState, {
          team: {
            roles: [{
              user_id: 1,
              type: 'owner'
            }]
          }
        });
      });

      it('pushes role onto user', () => {
        expect(afterState.roles).to.have.length(1);
      });
    });
  });

  describe('USER_DELETED', () => {
    let beforeState;
    let afterState;
    beforeEach(() => {
      beforeState = {
        id: 1,
        roles: [{
          team_id: 77
        }, {
          team_id: 12345
        }]
      };
    });

    describe('when current user has not been deleted', () => {
      beforeEach(() => {
        afterState = users.get(ActionTypes.USER_DELETED)(beforeState, {
          id: 2,
          isSelf: false,
          team: {
            id: 12345
          }
        });
      });

      it('does not modify state', () => {
        expect(afterState).to.eq(beforeState);
      });
    });

    describe('when current user has been deleted', () => {
      beforeEach(() => {
        afterState = users.get(ActionTypes.USER_DELETED)(beforeState, {
          id: 1,
          isSelf: true,
          team: {
            id: 77
          }
        });
      });

      it('removes role from user', () => {
        expect(afterState.roles).to.have.length(1);
      });
    });
  });
});
