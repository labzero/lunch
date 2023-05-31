/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import canChangeUser from "../canChangeUser";
import { Team, User } from "../../interfaces";

describe("helpers/canChangeUser", () => {
  let user: User;
  let userToChange: User;
  let team: Team;
  let users: User[];

  beforeEach(() => {
    user = {
      name: "dev",
      id: 1,
      superuser: false,
      roles: [{ type: "owner", teamId: 1, userId: 1 }],
      email: "dev@labzero.com",
    } as User;
    userToChange = {
      name: "test",
      id: 2,
      type: "member",
      email: "test@labzero.com",
    } as User;
    team = {
      id: 1,
    } as Team;
    users = [
      {
        name: "dev",
        id: 1,
        type: "owner",
        email: "dev@labzero.com",
      },
      {
        name: "test",
        id: 2,
        type: "member",
        email: "test@labzero.com",
      },
    ] as User[];
  });

  it("returns true when user is superuser", () => {
    user.superuser = true;
    expect(canChangeUser(user, userToChange, team, users)).to.be.true;
  });

  describe("when user role is owner and changing their own role", () => {
    beforeEach(() => {
      userToChange = {
        name: "dev",
        id: 1,
        type: "owner",
        email: "dev@labzero.com",
      } as User;
    });

    it("returns false when there are no other owners", () => {
      expect(canChangeUser(user, userToChange, team, users)).to.be.false;
    });

    it("returns true when there are other owners", () => {
      users[1].type = "owner";
      expect(canChangeUser(user, userToChange, team, users)).to.be.true;
    });
  });

  it("returns true when user role is owner and none of above conditions are met", () => {
    expect(canChangeUser(user, userToChange, team, users)).to.be.true;
  });
});
