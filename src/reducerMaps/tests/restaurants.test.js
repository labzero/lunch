/* eslint-env mocha */

import { expect } from 'chai';
import ActionTypes from '../../constants/ActionTypes';
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
                votes: [1],
              },
              2: {
                id: 2,
                name: 'Ferry Building',
                votes: [2, 3, 4, 5, 6],
              },
              3: {
                id: 3,
                name: 'Ramen Grill',
                votes: [7, 8],
              },
              4: {
                id: 4,
                name: 'Taco Deli',
                votes: [],
              }
            }
          },
        result: [1,2,3,4]
      }
    };

      afterState = restaurants.get(ActionTypes.SORT_RESTAURANTS)(beforeState, {
        decision: {restaurant_id: 3},
        newlyAdded: {id: 4, userId: 1},
        user: {id: 1}
      });
    });

    it('places new restaurant at the top', () => {
      expect(afterState.items.result[0]).to.eq(4);
    });

    it('places restaurant with decison below new restaurants', () => {
      expect(afterState.items.result[1]).to.eq(3);
    });

    it('places restaurant with more votes above restaurants with fewer votes', () => {
      expect(afterState.items.result[2]).to.eq(2);
      expect(afterState.items.result[3]).to.eq(1);
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
                all_decision_count: "1",
              },
              2: {
                id: 2,
                name: 'Ferry Building',
                all_decision_count: "1",
              }
            }
          }
        }
      };

      afterState = restaurants.get(ActionTypes.DECISION_POSTED)(beforeState, {
        decision: {
          restaurant_id: 1
        },
        deselected: [{
          restaurant_id: 2
        }]
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
