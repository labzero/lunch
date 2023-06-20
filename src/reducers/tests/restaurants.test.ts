/* eslint-env mocha */

import { expect } from "chai";
import { Decision, Restaurant, State, User } from "../../interfaces";
import restaurants from "../restaurants";

describe("reducers/restaurants", () => {
  let beforeState: State["restaurants"];
  let afterState: State["restaurants"];

  describe("SORT_RESTAURANTS", () => {
    beforeEach(() => {
      beforeState = {
        didInvalidate: false,
        isFetching: false,
        items: {
          entities: {
            restaurants: {
              1: {
                id: 1,
                name: "Tokyo Express",
                votes: [1, 2],
                all_vote_count: 0,
              } as Restaurant,
              2: {
                id: 2,
                name: "Ferry Building",
                votes: [2, 3, 4, 5, 6],
                all_vote_count: 0,
              } as Restaurant,
              3: {
                id: 3,
                name: "Ramen Grill",
                votes: [7],
                all_vote_count: 5,
              } as Restaurant,
              4: {
                id: 4,
                name: "Burger Bonanza",
                votes: [7],
                all_vote_count: 10,
              } as Restaurant,
              5: {
                id: 5,
                name: "Sandwich Area",
                votes: [7, 8],
                all_vote_count: 0,
              } as Restaurant,
              6: {
                id: 6,
                name: "Taco Deli",
                votes: [] as number[],
                all_vote_count: 0,
              } as Restaurant,
            },
          },
          result: [1, 2, 3, 4, 5, 6],
        },
        nameFilter: "",
      };

      afterState = restaurants(beforeState, {
        decision: { restaurantId: 5 } as Decision,
        newlyAdded: { id: 6, userId: 1 },
        type: "SORT_RESTAURANTS",
        user: { id: 1 } as User,
      });
    });

    it("places new restaurant at the top", () => {
      expect(afterState.items.result[0]).to.eq(6);
    });

    it("places restaurant with decison below new restaurants", () => {
      expect(afterState.items.result[1]).to.eq(5);
    });

    it("places restaurant with more votes above restaurants with fewer votes", () => {
      expect(afterState.items.result[2]).to.eq(2);
      expect(afterState.items.result[3]).to.eq(1);
    });

    it("places restaurant with more past votes above restaurants with fewer past votes", () => {
      expect(afterState.items.result[4]).to.eq(4);
      expect(afterState.items.result[5]).to.eq(3);
    });
  });

  describe("DECISION_POSTED", () => {
    beforeEach(() => {
      beforeState = {
        didInvalidate: false,
        isFetching: false,
        items: {
          entities: {
            restaurants: {
              1: {
                id: 1,
                name: "Tokyo Express",
                all_decision_count: "1",
              } as Restaurant,
              2: {
                id: 2,
                name: "Ferry Building",
                all_decision_count: "1",
              } as Restaurant,
            },
          },
          result: [1, 2],
        },
        nameFilter: "",
      };

      afterState = restaurants(beforeState, {
        decision: {
          restaurantId: 1,
        } as Decision,
        deselected: [
          {
            restaurantId: 2,
          } as Decision,
        ],
        type: "DECISION_POSTED",
        userId: 1,
      });
    });

    it("increments the decision count for the chosen restaurant", () => {
      expect(afterState.items.entities.restaurants[1].all_decision_count).to.eq(
        2
      );
    });

    it("decrements the decision count for any unselected restaurants", () => {
      expect(afterState.items.entities.restaurants[2].all_decision_count).to.eq(
        0
      );
    });
  });
});
