/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import ActionTypes from '../../constants/ActionTypes';
import users from '../user';

describe('reducerMaps/user', () => {
  describe('USER_ROLE_ADDED', () => {
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
        afterState = users.get(ActionTypes.USER_ROLE_ADDED)(beforeState, {
          role: {
            user_id: 2,
            type: 'owner'
          }
        });
      });

      it('does not modify state', () => {
        expect(afterState).to.eq(beforeState);
      });
    });

    describe('when role is on logged-in user', () => {
      beforeEach(() => {
        afterState = users.get(ActionTypes.USER_ROLE_ADDED)(beforeState, {
          role: {
            user_id: 1,
            type: 'owner'
          }
        });
      });

      it('pushes role onto user', () => {
        expect(afterState.roles).to.have.length(1);
      });
    });
  });
});
