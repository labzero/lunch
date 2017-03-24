/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import ActionTypes from '../../constants/ActionTypes';
import users from '../users';

describe('reducerMaps/users', () => {
  describe('USER_PATCHED', () => {
    let beforeState;
    let afterState;
    beforeEach(() => {
      beforeState = {
        isFetching: false,
        items: {
          results: [1],
          entities: {
            users: {
              1: {
                foo: 'bar'
              }
            }
          }
        }
      };
      afterState = users.get(ActionTypes.USER_PATCHED)(beforeState, {
        id: 1,
        user: {
          foo: 'baz'
        }
      });
    });

    it('sets isFetching to false', () => {
      expect(afterState.isFetching).to.be.false;
    });

    it('replaces user with updated user', () => {
      expect(afterState.items.entities.users[1].foo).to.eq('baz');
    });
  });
});
