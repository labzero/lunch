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
import * as teams from "../teams";

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe("actions/teams", () => {
  let store: MockStoreEnhanced<State, Action, Dispatch>;

  beforeEach(() => {
    store = mockStore({});
  });

  describe("createTeam", () => {
    const payload = { name: "bar" };

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches postTeam", () => {
        return store.dispatch(teams.createTeam(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("POST_TEAM");
          expect("team" in actions[0] && actions[0].team).to.eql({
            name: "bar",
          });
        });
      });

      it("fetches restaurant", () => {
        store.dispatch(teams.createTeam(payload));

        expect(fetchMock.lastCall()![0]).to.eq("/api/teams");
        expect(fetchMock.lastCall()![1]!.body).to.eq(JSON.stringify(payload));
      });
    });

    describe("success", () => {
      const team = {
        foo: "bar",
        roles: [
          {
            id: 1,
            teamId: 2,
            userId: 3,
          },
        ],
      };

      beforeEach(() => {
        fetchMock.mock("*", {
          data: team,
        });
      });

      it("dispatches teamPosted", () => {
        return store.dispatch(teams.createTeam(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("TEAM_POSTED");
          expect("team" in actions[1] && actions[1].team).to.eql(team);
        });
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(teams.createTeam(payload)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });
});
