/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates, arrow-body-style */

import { expect } from "chai";
import {
  MockStoreEnhanced,
  configureMockStore,
} from "@jedmao/redux-mock-store";
import fetchMock from "fetch-mock";
import proxyquire from "proxyquire";
import thunk from "redux-thunk";
import { Action, Dispatch, State, User } from "../../interfaces";
import * as users from "../users";

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe("actions/users", () => {
  let store: MockStoreEnhanced<State, Action, Dispatch>;

  beforeEach(() => {
    store = mockStore({
      team: { id: 1 },
    });
  });

  describe("fetchUsers", () => {
    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches requestUsers", () => {
        return store.dispatch(users.fetchUsers()).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("REQUEST_USERS");
        });
      });

      it("fetches users", () => {
        store.dispatch(users.fetchUsers());

        expect(fetchMock.lastCall()![0]).to.eq("/api/users");
      });
    });

    describe("success", () => {
      beforeEach(() => {
        fetchMock.mock("*", { data: [{ foo: "bar" }] });
      });

      it("dispatches receiveUsers", () => {
        return store.dispatch(users.fetchUsers()).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("RECEIVE_USERS");
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
        return store.dispatch(users.fetchUsers()).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("addUser", () => {
    let payload: Partial<User>;

    beforeEach(() => {
      payload = { email: "foo@bar.com" };
    });

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches postUser", () => {
        return store.dispatch(users.addUser(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("POST_USER");
          expect("user" in actions[0] && actions[0].user).to.eql({
            email: "foo@bar.com",
          });
        });
      });

      it("fetches restaurant", () => {
        store.dispatch(users.addUser(payload));

        expect(fetchMock.lastCall()![0]).to.eq("/api/users");
        expect(fetchMock.lastCall()![1]!.body).to.eq(JSON.stringify(payload));
      });
    });

    describe("success", () => {
      beforeEach(() => {
        fetchMock.mock("*", { data: { foo: "bar" } });
      });

      it("dispatches userPosted", () => {
        return store.dispatch(users.addUser(payload)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("USER_POSTED");
          expect("user" in actions[1] && actions[1].user).to.eql({
            foo: "bar",
          });
        });
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(users.addUser(payload)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("removeUser", () => {
    let id = 1;
    const proxyUsers = proxyquire("../users", {
      "../selectors/user": {
        getCurrentUser: () => {
          return { id: 231 };
        },
      },
    });

    beforeEach(() => {
      id = 1;
    });

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches deleteUser", () => {
        return store.dispatch(proxyUsers.removeUser(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("DELETE_USER");
          expect("id" in actions[0] && actions[0].id).to.eq(1);
        });
      });

      it("fetches user", () => {
        store.dispatch(proxyUsers.removeUser(id));

        expect(fetchMock.lastCall()![0]).to.eq(`/api/users/${id}`);
      });
    });

    describe("when id is of current user", () => {
      beforeEach(() => {
        id = 231;
        fetchMock.mock("*", {});
      });

      it("dispatches deleteUser with isSelf = true", () => {
        return store.dispatch(proxyUsers.removeUser(id)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("DELETE_USER");
          expect("isSelf" in actions[0] && actions[0].isSelf).to.eq(true);
          expect("id" in actions[0] && actions[0].id).to.eq(231);
          expect("team" in actions[0] && actions[0].team).to.eq(undefined);
        });
      });
    });

    describe("when team is provided", () => {
      const team = {
        slug: "labzero",
      };

      beforeEach(() => {
        store = mockStore({
          host: "lunch.pink",
        });
        fetchMock.mock("*", {});
      });

      it("dispatches deleteUser with team", () => {
        return store.dispatch(proxyUsers.removeUser(id, team)).then(() => {
          const actions = store.getActions();
          expect(actions[0].type).to.eq("DELETE_USER");
          expect("team" in actions[0] && actions[0].team).to.eql({
            slug: "labzero",
          });
          expect("id" in actions[0] && actions[0].id).to.eq(1);
        });
      });

      it("fetches user with full url", () => {
        store.dispatch(proxyUsers.removeUser(id, team));
        expect(fetchMock.lastCall()![0]).to.eq(
          `http://${team.slug}.lunch.pink/api/users/${id}`
        );
      });
    });

    describe("success", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches userDeleted", () => {
        return store.dispatch(proxyUsers.removeUser(id)).then(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("USER_DELETED");
          expect("id" in actions[1] && actions[1].id).to.eq(1);
        });
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store.dispatch(proxyUsers.removeUser(id)).catch(() => {
          const actions = store.getActions();
          expect(actions[1].type).to.eq("FLASH_ERROR");
        });
      });
    });
  });

  describe("changeUserRole", () => {
    const id = 1;
    const roleType = "member";
    const proxyUsers = proxyquire("../users", {
      "../selectors/user": {
        getCurrentUser: () => {
          return { id: 231 };
        },
      },
    });

    describe("before fetch", () => {
      beforeEach(() => {
        fetchMock.mock("*", {});
      });

      it("dispatches patchUser", () => {
        return store
          .dispatch(proxyUsers.changeUserRole(id, roleType))
          .then(() => {
            const actions = store.getActions();
            expect(actions[0].type).to.eq("PATCH_USER");
            expect("id" in actions[0] && actions[0].id).to.eq(1);
            expect("roleType" in actions[0] && actions[0].roleType).to.eq(
              "member"
            );
          });
      });

      it("fetches user", () => {
        store.dispatch(proxyUsers.changeUserRole(id, roleType));

        expect(fetchMock.lastCall()![0]).to.eq(`/api/users/${id}`);
        expect(fetchMock.lastCall()![1]!.body).to.eq(
          JSON.stringify({ id, type: roleType })
        );
      });
    });

    describe("success", () => {
      beforeEach(() => {
        fetchMock.mock("*", { data: { foo: "bar" } });
      });

      it("dispatches userPatched", () => {
        return store
          .dispatch(proxyUsers.changeUserRole(id, roleType))
          .then(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("USER_PATCHED");
            expect("id" in actions[1] && actions[1].id).to.eq(1);
            expect("user" in actions[1] && actions[1].user).to.eql({
              foo: "bar",
            });
          });
      });
    });

    describe("failure", () => {
      beforeEach(() => {
        fetchMock.mock("*", 400);
      });

      it("dispatches flashError", () => {
        return store
          .dispatch(proxyUsers.changeUserRole(id, roleType))
          .catch(() => {
            const actions = store.getActions();
            expect(actions[1].type).to.eq("FLASH_ERROR");
          });
      });
    });
  });
});
