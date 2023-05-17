/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { match, spy, stub } from "sinon";
import bodyParser from "body-parser";
import request from "supertest";
import express from "express";
import proxyquire from "proxyquire";
import SequelizeMock from "sequelize-mock";
import mockEsmodule from "../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe("middlewares/users", () => {
  let app;
  let createSpy;
  let destroySpy;
  let makeApp;
  let sendMailSpy;
  let InvitationMock;
  let UserMock;
  let flashSpy;

  beforeEach(() => {
    InvitationMock = dbMock.define("invitation", {});
    destroySpy = spy(InvitationMock, "destroy");
    UserMock = dbMock.define("user", {});
    createSpy = spy(UserMock, "create");
    sendMailSpy = spy();
    flashSpy = spy();
    makeApp = (deps, middleware) => {
      const usersMiddleware = proxyquireStrict("../users", {
        "../helpers/generateToken": mockEsmodule({
          default: () => "12345",
        }),
        "../models": mockEsmodule({
          Invitation: InvitationMock,
          User: UserMock,
        }),
        "../mailers/transporter": mockEsmodule({
          default: {
            sendMail: sendMailSpy,
          },
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
      server.use((req, res, next) => {
        req.flash = flashSpy; // eslint-disable-line no-param-reassign
        req.session = {
          // eslint-disable-line no-param-reassign
          save: (cb) => cb(),
        };
        next();
      });
      server.use("/", usersMiddleware());
      return server;
    };

    app = makeApp();
  });

  describe("POST /", () => {
    describe("if current user is a superuser", () => {
      beforeEach(() => {
        app = makeApp({}, (req, res, next) => {
          req.user = {
            get: () => true,
          };
          next();
        });

        return request(app)
          .post("/")
          .send({ email: "jeffrey@labzero.com", name: "Jeffrey" });
      });

      it("creates user", () => {
        expect(
          createSpy.calledWith({
            email: "jeffrey@labzero.com",
            name: "Jeffrey",
            resetPasswordToken: "12345",
            resetPasswordSentAt: match.date,
          })
        ).to.be.true;
      });

      it("destroys any existing invitations", () => {
        expect(
          destroySpy.calledWith({
            where: {
              email: "jeffrey@labzero.com",
            },
          })
        ).to.be.true;
      });

      it("sends mail", () => {
        expect(
          sendMailSpy.calledWith({
            name: "Jeffrey",
            email: "jeffrey@labzero.com",
            subject: match.string,
            text: match.string,
          })
        ).to.be.true;
      });
    });

    describe("if current user is not a superuser", () => {
      beforeEach(() => {
        app = makeApp({}, (req, res, next) => {
          req.user = {
            get: () => false,
          };
          next();
        });

        return request(app)
          .post("/")
          .send({ email: "jeffrey@labzero.com", name: "Jeffrey" });
      });

      it("does not create any user", () => {
        expect(createSpy.callCount).to.eq(0);
      });

      it("does not destroy invitations", () => {
        expect(destroySpy.callCount).to.eq(0);
      });

      it("does not send mail", () => {
        expect(sendMailSpy.callCount).to.eq(0);
      });
    });

    describe("failure", () => {
      let response;
      beforeEach((done) => {
        app = makeApp({}, (req, res, next) => {
          req.user = {
            get: () => true,
          };
          next();
        });

        UserMock.create.restore();
        stub(UserMock, "create").throws();

        request(app)
          .post("/")
          .send({ email: "jeffrey@labzero.com", name: "Jeffrey" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("flashes error message", () => {
        expect(flashSpy.calledWith("error", match.string)).to.be.true;
      });

      it("redirects to new page", () => {
        expect(response.headers.location).to.eq("/users/new");
      });
    });
  });
});
