/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { SinonSpy, spy, stub } from "sinon";
import bodyParser from "body-parser";
import { Response } from "superagent";
import request from "supertest";
import express, { Application, RequestHandler } from "express";
import proxyquire from "proxyquire";
import SequelizeMock from "sequelize-mock";
import mockEsmodule from "../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe("api/main/user", () => {
  let app: Application;
  let UserMock: SequelizeMockObject;
  let loggedInSpy: SinonSpy;
  let makeApp: (deps?: any, middleware?: RequestHandler) => Application;
  let updateSpy: SinonSpy;

  beforeEach(() => {
    UserMock = dbMock.define("user", {});
    UserMock.getSessionUser = () => Promise.resolve({});

    updateSpy = spy();

    loggedInSpy = spy((req, res, next) => {
      req.user = {
        // eslint-disable-line no-param-reassign
        get: () => undefined,
        name: "Old Name",
        id: 231,
        roles: [],
        update: updateSpy,
      };
      next();
    });

    makeApp = (deps, middleware) => {
      const userApi = proxyquireStrict("../main/user", {
        "../../db": mockEsmodule({
          User: UserMock,
        }),
        "../helpers/loggedIn": mockEsmodule({
          default: loggedInSpy,
        }),
        ...deps,
      }).default;

      const server = express();
      server.use(bodyParser.json());
      server.use((req, res, next) => {
        if (middleware) {
          middleware(req, res, next);
        } else {
          next();
        }
      });
      server.use("/", userApi());
      return server;
    };

    app = makeApp();
  });

  describe("PATCH /:id", () => {
    describe("before updating", () => {
      beforeEach(() => request(app).patch("/"));

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });
    });

    describe("without valid parameters", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .patch("/")
          .send({ id: 123 })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 422", () => {
        expect(response.statusCode).to.eq(422);
      });

      it("returns json with error", () => {
        expect(response.body.error).to.eq(true);
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("with at least one valid parameter", () => {
      beforeEach(() =>
        request(app).patch("/").send({ name: "New Name", id: 123 })
      );

      it("updates user", () => {
        expect(updateSpy.callCount).to.eq(1);
      });
    });

    describe("with bad password", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/getPasswordError": mockEsmodule({
            default: () => "Bad Password!!!",
          }),
        });

        request(app)
          .patch("/")
          .send({ password: "badpassword" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 422", () => {
        expect(response.statusCode).to.eq(422);
      });

      it("returns json with error", () => {
        expect(response.body.error).to.eq(true);
        expect(response.body.data.message).to.eq("Bad Password!!!");
      });
    });

    describe("with good password", () => {
      beforeEach(() => {
        app = makeApp({
          "../../helpers/getPasswordError": mockEsmodule({
            default: () => undefined,
          }),
          "../../helpers/getUserPasswordUpdates": mockEsmodule({
            default: () =>
              Promise.resolve({
                encryptedPassword: "drowssapdoog",
              }),
          }),
        });

        return request(app).patch("/").send({ password: "goodpassword" });
      });

      it("updates with password updates, not password", () => {
        expect(updateSpy.calledWith({ encryptedPassword: "drowssapdoog" })).to
          .be.true;
      });
    });

    describe("with new name", () => {
      beforeEach(() => request(app).patch("/").send({ name: "New Name" }));

      it("sets namedChanged", () => {
        expect(updateSpy.calledWith({ name: "New Name", namedChanged: true }))
          .to.be.true;
      });
    });

    describe("success", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .patch("/")
          .send({ name: "New Name" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 200", () => {
        expect(response.statusCode).to.eq(200);
      });

      it("returns json with user", () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).to.be.an("object");
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../helpers/loggedIn": mockEsmodule({
            default: spy((req, res, next) => {
              req.user = {
                // eslint-disable-line no-param-reassign
                get: () => undefined,
                id: 231,
                roles: [],
                update: stub().throws("Oh No"),
              };
              next();
            }),
          }),
        });

        request(app)
          .patch("/")
          .send({ name: "New Name" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns error", () => {
        expect(
          typeof response.error !== "boolean" && response.error.text
        ).to.contain("Oh No");
      });
    });
  });
});
