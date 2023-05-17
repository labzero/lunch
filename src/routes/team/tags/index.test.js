/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from "chai";
import { configureMockStore } from "@jedmao/redux-mock-store";
import proxyquire from "proxyquire";
import mockEsmodule from "../../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();
const mockStore = configureMockStore();

describe("routes/team/tags", () => {
  let context;
  let render404;
  let team;
  let landingProxy;

  beforeEach(() => {
    team = {
      id: 77,
    };
    context = {
      params: {},
      store: mockStore({
        team,
        user: {
          id: 1,
        },
      }),
    };
  });

  describe("when user is not on team", () => {
    let result;
    beforeEach(() => {
      render404 = "render404";
      landingProxy = proxyquireStrict("./index", {
        "../../../helpers/hasRole": mockEsmodule({
          default: () => false,
        }),
        "../../helpers/renderIfHasName": mockEsmodule({
          default: (_, cb) => cb(),
        }),
        "../../helpers/render404": mockEsmodule({
          default: () => render404,
        }),
      }).default;
      result = landingProxy(context);
    });

    it("renders 404", () => {
      expect(result).to.eq(render404);
    });
  });

  describe("when user is on team", () => {
    let result;
    beforeEach(() => {
      landingProxy = proxyquireStrict("./index", {
        "../../../helpers/hasRole": mockEsmodule({
          default: () => true,
        }),
        "../../helpers/renderIfHasName": mockEsmodule({
          default: (_, cb) => cb(),
        }),
      }).default;
      result = landingProxy(context);
    });

    it("renders team", () => {
      expect(result).to.have.keys("component", "chunks", "title");
    });
  });
});
