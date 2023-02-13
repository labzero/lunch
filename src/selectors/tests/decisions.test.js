/* eslint-env mocha */
import dayjs from 'dayjs';
import { expect } from 'chai';
import { getDecisionsByDay } from '../decisions';

describe('selectors/decisions', () => {
  describe('getDecisionsByDay', () => {
    let state;
    beforeEach(() => {
      const now = dayjs();

      state = {
        decisions: {
          items: {
            result: [1, 2, 3, 4],
            entities: {
              decisions: {
                1: {
                  createdAt: dayjs(now),
                },
                2: {
                  createdAt: dayjs(now).subtract(23, 'hours'),
                },
                3: {
                  createdAt: dayjs(now).subtract(25, 'hours'),
                },
                4: {
                  createdAt: dayjs(now).subtract(48, 'hours'),
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
