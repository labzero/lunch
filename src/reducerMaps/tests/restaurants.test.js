/* eslint-env mocha */

import { expect } from 'chai';
import restaurants from '../restaurants';

describe('reducerMaps/restaurants', () => {
  describe('SORT_RESTAURANTS', () => {
    let beforeState;
    let afterState;

    beforeEach(() => {
      beforeState = {
        isFetching: false,
        items: {
          entities: {
            restaurants: {
              1: {
                id: 1,
                name: 'Tokyo Express',
                votes: [1, 2],
                all_vote_count: 0,
              },
              2: {
                id: 2,
                name: 'Ferry Building',
                votes: [2, 3, 4, 5, 6],
                all_vote_count: 0,
              },
              3: {
                id: 3,
                name: 'Ramen Grill',
                votes: [7],
                all_vote_count: 5,
              },
              4: {
                id: 4,
                name: 'Burger Bonanza',
                votes: [7],
                all_vote_count: 10
              },
              5: {
                id: 5,
                name: 'Sandwich Area',
                votes: [7, 8],
                all_vote_count: 0,
              },
              6: {
                id: 6,
                name: 'Taco Deli',
                votes: [],
                all_vote_count: 0,
              }
            }
          },
          result: [1, 2, 3, 4, 5, 6]
        }
      };

      afterState = restaurants(beforeState, {
        decision: { restaurantId: 5 },
        newlyAdded: { id: 6, userId: 1 },
        type: 'SORT_RESTAURANTS',
        user: { id: 1 }
      });
    });

    it('places new restaurant at the top', () => {
      expect(afterState.items.result[0]).to.eq(6);
    });

    it('places restaurant with decison below new restaurants', () => {
      expect(afterState.items.result[1]).to.eq(5);
    });

    it('places restaurant with more votes above restaurants with fewer votes', () => {
      expect(afterState.items.result[2]).to.eq(2);
      expect(afterState.items.result[3]).to.eq(1);
    });

    it('places restaurant with more past votes above restaurants with fewer past votes', () => {
      expect(afterState.items.result[4]).to.eq(4);
      expect(afterState.items.result[5]).to.eq(3);
    });
  });

  describe('DECISION_POSTED', () => {
    let beforeState;
    let afterState;

    beforeEach(() => {
      beforeState = {
        isFetching: false,
        items: {
          entities: {
            restaurants: {
              1: {
                id: 1,
                name: 'Tokyo Express',
                all_decision_count: '1',
              },
              2: {
                id: 2,
                name: 'Ferry Building',
                all_decision_count: '1',
              }
            }
          }
        }
      };

      afterState = restaurants(beforeState, {
        decision: {
          restaurantId: 1
        },
        deselected: [{
          restaurantId: 2
        }],
        type: 'DECISION_POSTED'
      });
    });

    it('increments the decision count for the chosen restaurant', () => {
      expect(afterState.items.entities.restaurants[1].all_decision_count).to.eq(2);
    });

    it('decrements the decision count for any unselected restaurants', () => {
      expect(afterState.items.entities.restaurants[2].all_decision_count).to.eq(0);
    });
  });
});
