/* eslint-env mocha */
import moment from 'moment';
import { expect } from 'chai';
import { getDecisionsByDay } from '../decisions';

describe('selectors/decisions', () => {
  describe('getDecisionsByDay', () => {
    let state;
    beforeEach(() => {
      const now = moment();

      state = {
        decisions: {
          items: {
            result: [1, 2, 3, 4],
            entities: {
              decisions: {
                1: {
                  created_at: moment(now),
                },
                2: {
                  created_at: moment(now).subtract(23, 'hours'),
                },
                3: {
                  created_at: moment(now).subtract(25, 'hours'),
                },
                4: {
                  created_at: moment(now).subtract(48, 'hours'),
                },
              },
            },
          },
        },
      };
    });

    it('groups decisions into per-day arrays', () => {
      const decisions = state.decisions.items.entities.decisions;
      expect(getDecisionsByDay(state)).to.eql({
        0: [decisions[1]],
        1: [decisions[2], decisions[3]],
        2: [decisions[4]],
        3: [],
        4: [],
      });
    });
  });
});
