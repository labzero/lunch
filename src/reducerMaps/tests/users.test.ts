/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { State, Team, User } from "../../interfaces";
import users from "../users";

describe("reducerMaps/users", () => {
  let beforeState: State["users"];
  let afterState: State["users"];

  describe("USER_PATCHED", () => {
    beforeEach(() => {
      beforeState = {
        didInvalidate: false,
        isFetching: false,
        items: {
          result: [1],
          entities: {
            users: {
              1: {
                name: "bar",
              } as User,
            },
          },
        },
      };
      afterState = users(beforeState, {
        id: 1,
        isSelf: false,
        team: {
          id: 1,
        } as Team,
        type: "USER_PATCHED",
        user: {
          name: "baz",
        } as User,
      });
    });

    it("sets isFetching to false", () => {
      expect(afterState.isFetching).to.be.false;
    });

    it("replaces user with updated user", () => {
      expect(afterState.items.entities.users[1].name).to.eq("baz");
    });
  });
});
