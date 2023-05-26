/// <reference types="mocha" />

/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from "chai";
import proxyquire from "proxyquire";
import { configureMockStore } from "@jedmao/redux-mock-store";
import mockEsmodule from "../../../../test/mockEsmodule";
import { AppContext } from "../../../interfaces";

const proxyquireStrict = proxyquire.noCallThru();
const mockStore = configureMockStore();

describe("routes/team/team", () => {
  let context: Partial<Omit<AppContext, "store">>;
  let render404: string;
  let team;
  let landingProxy;

  beforeEach(() => {
    team = {
      id: 77,
    };
    context = {
      params: {},
      query: {},
      store: mockStore({
        team,
        user: {
          id: 1,
          roles: [],
        },
      }),
    };
  });

  describe("when user is a guest", () => {
    it("renders 404", function test() {
      this.timeout(8000);
      render404 = "render404";
      landingProxy = proxyquireStrict("./index", {
        "../../../helpers/hasRole": mockEsmodule({
          default: () => false,
        }),
        "../../helpers/renderIfHasName": mockEsmodule({
          default: (_: AppContext, cb: () => void) => cb(),
        }),
        "../../helpers/render404": mockEsmodule({
          default: () => render404,
        }),
      }).default;
      expect(landingProxy(context)).to.eq(render404);
    });
  });

  describe("when user is at least a member", () => {
    it("renders team", () => {
      landingProxy = proxyquireStrict("./index", {
        "../../../helpers/hasRole": mockEsmodule({
          default: () => true,
        }),
        "../../helpers/renderIfHasName": mockEsmodule({
          default: (_: AppContext, cb: () => void) => cb(),
        }),
      }).default;

      expect(landingProxy(context)).to.have.keys(
        "component",
        "chunks",
        "map",
        "title"
      );
    });
  });
});
