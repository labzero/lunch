/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from "chai";
import { configureMockStore } from "@jedmao/redux-mock-store";
import { SinonSpy, spy } from "sinon";
import proxyquire from "proxyquire";
import { AppContext } from "../../../interfaces";
import mockEsmodule from "../../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();
const mockStore = configureMockStore();

describe("routes/helpers/renderIfHasName", () => {
  let makeRouteSpy: SinonSpy;
  let context: Omit<AppContext, "store">;

  beforeEach(() => {
    makeRouteSpy = spy();
  });

  describe("when there is no user", () => {
    let redirectToLoginSpy: SinonSpy;
    let renderIfHasNameProxy;
    beforeEach(() => {
      redirectToLoginSpy = spy();
      renderIfHasNameProxy = proxyquireStrict("../renderIfHasName", {
        "./redirectToLogin": mockEsmodule({
          default: redirectToLoginSpy,
        }),
      }).default;
      context = {
        store: mockStore({
          user: null,
        }),
      };
      renderIfHasNameProxy(context, makeRouteSpy);
    });

    it("redirects to login", () => {
      expect(redirectToLoginSpy.calledWith(context)).to.be.true;
    });
  });
});
