/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from "chai";
import { spy } from "sinon";
import proxyquire from "proxyquire";
import renderIfLoggedOut from "../renderIfLoggedOut";

describe("routes/helpers/renderIfLoggedOut", () => {
  let makeRouteSpy;
  let state;
  let renderIfLoggedOutProxy;

  beforeEach(() => {
    makeRouteSpy = spy();
  });

  describe("when user has one role", () => {
    beforeEach(() => {
      renderIfLoggedOutProxy = proxyquire("../renderIfLoggedOut", {
        "../../selectors/teams": {
          getTeams: () => [
            {
              slug: "labzero",
            },
          ],
        },
      }).default;
      state = {
        host: "lunch.pink",
        user: {
          id: 1,
          roles: [{}],
        },
      };
    });

    it("redirects user to team home", () => {
      expect(renderIfLoggedOutProxy(state, makeRouteSpy)).to.deep.eq({
        redirect: "//labzero.lunch.pink",
      });
    });
  });

  describe("when user has no roles", () => {
    beforeEach(() => {
      state = {
        user: {
          id: 1,
          roles: [],
        },
      };
    });

    it("redirects user to teams list", () => {
      expect(renderIfLoggedOut(state, makeRouteSpy)).to.deep.eq({
        redirect: "/teams",
      });
    });
  });

  describe("when user has multiple roles", () => {
    beforeEach(() => {
      state = {
        user: {
          id: 1,
          roles: [{}, {}, {}],
        },
      };
    });

    it("redirects user to teams list", () => {
      expect(renderIfLoggedOut(state, makeRouteSpy)).to.deep.eq({
        redirect: "/teams",
      });
    });
  });

  describe("when there is no user", () => {
    beforeEach(() => {
      state = {
        user: null,
      };
      renderIfLoggedOut(state, makeRouteSpy);
    });

    it("renders landing page", () => {
      expect(makeRouteSpy.callCount).to.eq(1);
    });
  });
});
