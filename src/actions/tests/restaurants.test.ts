/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates, arrow-body-style */

import { expect } from "chai";
import {
  MockStoreEnhanced,
  configureMockStore,
} from "@jedmao/redux-mock-store";
import fetchMock from "fetch-mock";
import thunk from "redux-thunk";
import { Action, Dispatch, State } from "../../interfaces";
import * as restaurants from "../restaurants";

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe("actions/restaurants", () => {
  let store: MockStoreEnhanced<State, Action, Dispatch>;

  beforeEach(() => {
    store = mockStore({});
  });

  describe("fetchRestaurants", () => {
    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches requestRestaurants", () => {
        return store.dispatch(restaurants.fetchRestaurants()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("REQUEST_RESTAURANTS");
        });
      });

      it("fetches restaurants", () => {
        store.dispatch(restaurants.fetchRestaurants());
        expect(fetchMock.lastCall()![0]).to.eq("/api/restaurants");
      });
    });

    describe("success", () => {
      beforeEach(() => {
        fetchMock.mock("*", { data: [{ foo: "bar" }] });
      });

      it("dispatches receiveRestaurants", () => {
        return store.dispatch(restaurants.fetchRestaurants()).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("RECEIVE_RESTAURANTS");
          expect("items" in actions[1] && actions[1].items).to.eql([
            { foo: "bar" },
          ]);
        });
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(restaurants.fetchRestaurants()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("addRestaurant", () => {
    const name = "Lab Zero";
    const placeId = "12345";
    const address = "123 Main";
    const lat = 50;
    const lng = 100;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches postRestaurant", () => {
        return store
          .dispatch(restaurants.addRestaurant(name, placeId, address, lat, lng))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("POST_RESTAURANT");
            expect("restaurant" in actions[0] && actions[0].restaurant).to.eql({
              name: "Lab Zero",
              placeId: "12345",
              address: "123 Main",
              lat: 50,
              lng: 100,
            });
          });
      });

      it("fetches restaurant", () => {
        store.dispatch(
          restaurants.addRestaurant(name, placeId, address, lat, lng)
        );

        expect(fetchMock.lastCall()![0]).to.eq("/api/restaurants");
        expect(fetchMock.lastCall()![1]!.body).to.eq(
          JSON.stringify({
            name,
            placeId,
            address,
            lat,
            lng,
          })
        );
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(restaurants.addRestaurant(name, placeId, address, lat, lng))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });

  describe("removeRestaurant", () => {
    const id = 1;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches deleteRestaurant", () => {
        return store.dispatch(restaurants.removeRestaurant(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("DELETE_RESTAURANT");
          expect("id" in actions[0] && actions[0].id).to.eq(1);
        });
      });

      it("fetches restaurant", () => {
        store.dispatch(restaurants.removeRestaurant(id));
        expect(fetchMock.lastCall()![0]).to.eq(`/api/restaurants/${id}`);
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(restaurants.removeRestaurant(id)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("changeRestaurantName", () => {
    const id = 1;
    const name = "Lab Zero";

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches renameRestaurant", () => {
        return store
          .dispatch(restaurants.changeRestaurantName(id, name))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("RENAME_RESTAURANT");
            expect("id" in actions[0] && actions[0].id).to.eq(1);
            expect(
              "restaurant" in actions[0] && actions[0].restaurant.name
            ).to.eq("Lab Zero");
          });
      });

      it("fetches restaurant", () => {
        store.dispatch(restaurants.changeRestaurantName(id, name));

        expect(fetchMock.lastCall()![0]).to.eq(`/api/restaurants/${id}`);
        expect(fetchMock.lastCall()![1]!.body).to.eq(JSON.stringify({ name }));
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(restaurants.changeRestaurantName(id, name))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });

  describe("addVote", () => {
    const id = 1;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches postVote", () => {
        return store.dispatch(restaurants.addVote(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("POST_VOTE");
          expect("id" in actions[0] && actions[0].id).to.eq(1);
        });
      });

      it("fetches vote", () => {
        store.dispatch(restaurants.addVote(id));

        expect(fetchMock.lastCall()![0]).to.eq(`/api/restaurants/${id}/votes`);
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(restaurants.addVote(id)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("removeVote", () => {
    const restaurantId = 1;
    const id = 2;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches deleteVote", () => {
        return store
          .dispatch(restaurants.removeVote(restaurantId, id))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("DELETE_VOTE");
            expect(
              "restaurantId" in actions[0] && actions[0].restaurantId
            ).to.eq(1);
            expect("id" in actions[0] && actions[0].id).to.eq(2);
          });
      });

      it("fetches vote", () => {
        store.dispatch(restaurants.removeVote(restaurantId, id));

        expect(fetchMock.lastCall()![0]).to.eq(
          `/api/restaurants/${restaurantId}/votes/${id}`
        );
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(restaurants.removeVote(restaurantId, id))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });

  describe("addNewTagToRestaurant", () => {
    const id = 1;
    const name = "zap";

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches postNewTagToRestaurant", () => {
        return store
          .dispatch(restaurants.addNewTagToRestaurant(id, name))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("POST_NEW_TAG_TO_RESTAURANT");
            expect(
              "restaurantId" in actions[0] && actions[0].restaurantId
            ).to.eq(1);
            expect("value" in actions[0] && actions[0].value).to.eq("zap");
          });
      });

      it("fetches tag", () => {
        store.dispatch(restaurants.addNewTagToRestaurant(id, name));

        expect(fetchMock.lastCall()![0]).to.eq(`/api/restaurants/${id}/tags`);
        expect(fetchMock.lastCall()![1]!.body).to.eq(JSON.stringify({ name }));
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(restaurants.addNewTagToRestaurant(id, name))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });

  describe("addTagToRestaurant", () => {
    const restaurantId = 1;
    const id = 2;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches postTagToRestaurant", () => {
        return store
          .dispatch(restaurants.addTagToRestaurant(restaurantId, id))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("POST_TAG_TO_RESTAURANT");
            expect(
              "restaurantId" in actions[0] && actions[0].restaurantId
            ).to.eq(1);
            expect("id" in actions[0] && actions[0].id).to.eq(2);
          });
      });

      it("fetches tag", () => {
        store.dispatch(restaurants.addTagToRestaurant(restaurantId, id));

        expect(fetchMock.lastCall()![0]).to.eq(
          `/api/restaurants/${restaurantId}/tags`
        );
        expect(fetchMock.lastCall()![1]!.body).to.eq(JSON.stringify({ id }));
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(restaurants.addTagToRestaurant(restaurantId, id))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });

  describe("removeTagFromRestaurant", () => {
    const restaurantId = 1;
    const id = 2;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches deleteTagFromRestaurant", () => {
        return store
          .dispatch(restaurants.removeTagFromRestaurant(restaurantId, id))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("DELETE_TAG_FROM_RESTAURANT");
            expect(
              "restaurantId" in actions[0] && actions[0].restaurantId
            ).to.eq(1);
            expect("id" in actions[0] && actions[0].id).to.eq(2);
          });
      });

      it("fetches tag", () => {
        store.dispatch(restaurants.removeTagFromRestaurant(restaurantId, id));

        expect(fetchMock.lastCall()![0]).to.eq(
          `/api/restaurants/${restaurantId}/tags/${id}`
        );
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(restaurants.removeTagFromRestaurant(restaurantId, id))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });
});
