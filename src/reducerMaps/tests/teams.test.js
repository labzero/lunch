/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import ActionTypes from '../../constants/ActionTypes';
import teams from '../teams';

describe('reducerMaps/teams', () => {
  describe('USER_DELETED', () => {
    let beforeState;
    let afterState;
    beforeEach(() => {
      beforeState = {
        items: {
          result: [77, 12345],
          entities: {
            77: {},
            12345: {}
          }
        }
      };
    });

    describe('when current user has not been deleted', () => {
      beforeEach(() => {
        afterState = teams.get(ActionTypes.USER_DELETED)(beforeState, {
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
        afterState = teams.get(ActionTypes.USER_DELETED)(beforeState, {
          id: 1,
          isSelf: true,
          team: {
            id: 77
          }
        });
      });

      it('removes team from list', () => {
        expect(afterState.items.result).to.have.length(1);
      });
    });
  });
});
