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
import * as tags from "../tags";

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe("actions/tags", () => {
  let store: MockStoreEnhanced<State, Action, Dispatch>;

  beforeEach(() => {
    store = mockStore({
      user: {
        id: 1,
      },
    });
  });

  describe("fetchTags", () => {
    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches requestTags", () => {
        return store.dispatch(tags.fetchTags()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("REQUEST_TAGS");
        });
      });

      it("fetches tags", () => {
        store.dispatch(tags.fetchTags());
        expect(fetchMock.lastCall()![0]).to.eq("/api/tags");
      });
    });

    describe("success", () => {
      beforeEach(() => {
        fetchMock.mock("*", { data: [{ foo: "bar" }] });
      });

      it("dispatches receiveTags", () => {
        return store.dispatch(tags.fetchTags()).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("RECEIVE_TAGS");
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
        return store.dispatch(tags.fetchTags()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("removeTag", () => {
    const id = 1;

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches deleteTag", () => {
        return store.dispatch(tags.removeTag(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("DELETE_TAG");
          expect("id" in actions[0] && actions[0].id).to.eq(1);
        });
      });

      it("fetches restaurant", () => {
        store.dispatch(tags.removeTag(id));
        expect(fetchMock.lastCall()![0]).to.eq(`/api/tags/${id}`);
      });
    });

    describe("success", () => {
      beforeEach(() => {
        store = mockStore({
          user: {
            id: 1,
          },
        });
        fetchMock.mock("*", {});
      });

      it("dispatches tagDeleted", () => {
        return store.dispatch(tags.removeTag(id)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("TAG_DELETED");
          expect("id" in actions[1] && actions[1].id).to.eq(1);
        });
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(tags.removeTag(id)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });
});
