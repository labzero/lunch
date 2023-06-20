/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { State, Team, User } from "../../interfaces";
import users from "../user";

describe("reducers/user", () => {
  let beforeState: State["user"];
  let afterState: State["user"];

  describe("TEAM_POSTED", () => {
    beforeEach(() => {
      beforeState = {
        id: 1,
        roles: [],
      } as unknown as User;
    });

    describe("when role is on different user", () => {
      beforeEach(() => {
        afterState = users(beforeState, {
          team: {
            roles: [
              {
                userId: 2,
                type: "owner",
              },
            ],
          } as Team,
          type: "TEAM_POSTED",
        });
      });

      it("does not modify state", () => {
        expect(afterState).to.eq(beforeState);
      });
    });

    describe("when role is on logged-in user", () => {
      beforeEach(() => {
        afterState = users(beforeState, {
          team: {
            roles: [
              {
                userId: 1,
                type: "owner",
              },
            ],
          } as Team,
          type: "TEAM_POSTED",
        });
      });

      it("pushes role onto user", () => {
        expect(afterState!.roles).to.have.length(1);
      });
    });
  });

  describe("USER_DELETED", () => {
    beforeEach(() => {
      beforeState = {
        id: 1,
        roles: [
          {
            teamId: 77,
          },
          {
            teamId: 12345,
          },
        ],
      } as unknown as User;
    });

    describe("when current user has not been deleted", () => {
      beforeEach(() => {
        afterState = users(beforeState, {
          id: 2,
          isSelf: false,
          team: {
            id: 12345,
          } as Team,
          type: "USER_DELETED",
        });
      });

      it("does not modify state", () => {
        expect(afterState).to.eq(beforeState);
      });
    });

    describe("when current user has been deleted", () => {
      beforeEach(() => {
        afterState = users(beforeState, {
          id: 1,
          isSelf: true,
          team: {
            id: 77,
          } as Team,
          type: "USER_DELETED",
        });
      });

      it("removes role from user", () => {
        expect(afterState!.roles).to.have.length(1);
      });
    });
  });

  describe("USER_PATCHED", () => {
    beforeEach(() => {
      beforeState = {
        id: 1,
        roles: [
          {
            teamId: 77,
            type: "owner",
          },
          {
            teamId: 12345,
            type: "owner",
          },
        ],
      } as unknown as User;
    });

    describe("when current user has not been updated", () => {
      beforeEach(() => {
        afterState = users(beforeState, {
          id: 2,
          isSelf: false,
          user: { id: 1 } as User,
          team: {
            id: 12345,
          } as Team,
          type: "USER_PATCHED",
        });
      });

      it("does not modify state", () => {
        expect(afterState).to.eq(beforeState);
      });
    });

    describe("when current user has been updated", () => {
      beforeEach(() => {
        afterState = users(beforeState, {
          id: 1,
          isSelf: true,
          team: {
            id: 77,
          } as Team,
          type: "USER_PATCHED",
          user: {
            type: "member",
          } as User,
        });
      });

      it("updates user role", () => {
        expect(afterState!.roles[0].type).to.eq("member");
      });

      it("does not set type attribute", () => {
        expect(afterState!.type).to.be.undefined;
      });
    });
  });
});
