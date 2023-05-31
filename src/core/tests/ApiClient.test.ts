/* eslint-env mocha */
import { SinonSpy, spy } from "sinon";
import { expect } from "chai";
import proxyquire from "proxyquire";
import { processResponse as processResponseOrig } from "../ApiClient";

const proxyquireStrict = proxyquire.noCallThru();

describe("processResponse", () => {
  let processResponse: typeof processResponseOrig;
  let replaceSpy: SinonSpy;

  beforeEach(() => {
    replaceSpy = spy();
    processResponse = proxyquireStrict("../ApiClient.ts", {
      "../actions/flash": {
        flashError: (message: string) => ({
          type: "FLASH_ERROR",
          message,
        }),
      },
      "../history": {
        location: {
          pathname: "/team",
        },
        replace: replaceSpy,
      },
    }).processResponse;
  });

  it("returns data when successful", () => {
    const response = {
      json: () => Promise.resolve({ data: { foo: "bar" } }),
    };

    return processResponse(response as Response).then((data) => {
      expect(data).to.eql({ foo: "bar" });
    });
  });

  it("returns nothing when 204", () => {
    const response = {
      status: 204,
    };

    return processResponse(response as Response).then((data) => {
      expect(data).to.eq(undefined);
    });
  });

  it("flashes error message from 400 response", () => {
    const dispatch = spy();
    const response = {
      json: () => Promise.resolve({ data: { message: "Oh No" } }),
      status: 400,
    };

    return processResponse(response as Response, dispatch).catch((err) => {
      expect(dispatch.args[0][0].type).to.eq("FLASH_ERROR");
      expect(err).to.eq("Oh No");
    });
  });

  it("redirects to login from 401 response", () => {
    const dispatch = spy();
    const response = {
      json: () => Promise.resolve({}),
      status: 401,
    };

    return processResponse(response as Response, dispatch).catch(() => {
      expect(replaceSpy.args[0][0]).to.eq("/login?next=/team");
    });
  });
});
