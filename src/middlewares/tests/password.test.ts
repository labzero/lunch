/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { SinonSpy, match, spy, stub } from "sinon";
import bodyParser from "body-parser";
import request, { Response } from "supertest";
import express, { Application } from "express";
import session, { Session } from "express-session";
import proxyquire from "proxyquire";
import SequelizeMock from "sequelize-mock";
import mockEsmodule from "../../../test/mockEsmodule";
import { MakeApp } from "../../interfaces";

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe("middlewares/password", () => {
  let app: Application;
  let makeApp: MakeApp;
  let sendMailSpy: SinonSpy;
  let UserMock: SequelizeMockObject;
  let flashSpy: SinonSpy;

  beforeEach(() => {
    UserMock = dbMock.define("user", {});
    sendMailSpy = spy();
    flashSpy = spy();
    makeApp = (deps) => {
      const passwordMiddleware = proxyquireStrict("../password", {
        "../db": mockEsmodule({
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
      server.use(
        session({ resave: true, secret: "123456", saveUninitialized: true })
      );
      server.use((req, res, next) => {
        req.flash = flashSpy; // eslint-disable-line no-param-reassign
        stub(req.session, "save").callsFake(function save(this: Session, cb) {
          cb!({});
          return this;
        });
        next();
      });
      server.use("/", passwordMiddleware());
      return server;
    };

    app = makeApp();
  });

  describe("POST /", () => {
    let updateSpy: SinonSpy;
    beforeEach(() => {
      updateSpy = spy();
    });

    describe("when user exists", () => {
      beforeEach(() => {
        stub(UserMock, "findOne").callsFake(() =>
          Promise.resolve({
            update: updateSpy,
          })
        );

        return request(app).post("/").send({ email: "jeffrey@labzero.com" });
      });

      it("updates user with new token", () => {
        expect(
          updateSpy.calledWith({
            resetPasswordToken: match.string,
            resetPasswordSentAt: match.date,
          })
        ).to.be.true;
      });

      it("sends mail", () => {
        expect(sendMailSpy.callCount).to.eq(1);
      });
    });

    describe("when user does not exist", () => {
      beforeEach(() => {
        stub(UserMock, "findOne").callsFake(async () => null);

        return request(app).post("/").send({ email: "jeffrey@labzero.com" });
      });

      it("does not update any user", () => {
        expect(updateSpy.callCount).to.eq(0);
      });

      it("does not send mail", () => {
        expect(sendMailSpy.callCount).to.eq(0);
      });
    });
  });

  describe("PUT /", () => {
    describe("when user does not exist", () => {
      let response: Response;
      beforeEach((done) => {
        stub(UserMock, "findOne").callsFake(async () => null);

        request(app)
          .put("/")
          .send({
            password: "a great password",
            resetPasswordToken: "12345",
          })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 302", () => {
        expect(response.statusCode).to.eq(302);
      });

      it("redirects to password reset request page", () => {
        expect(response.headers.location).to.eq("/password/new");
      });
    });

    describe("when user does not have valid reset password token", () => {
      let response: Response;
      beforeEach((done) => {
        stub(UserMock, "findOne").callsFake(async () => ({
          resetPasswordValid: () => false,
        }));

        request(app)
          .put("/")
          .send({
            password: "a great password",
            resetPasswordToken: "12345",
          })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 302", () => {
        expect(response.statusCode).to.eq(302);
      });

      it("redirects to password reset request page", () => {
        expect(response.headers.location).to.eq("/password/new");
      });
    });

    describe("when user submits password that is too short", () => {
      let response: Response;
      let updateSpy: SinonSpy;
      beforeEach((done) => {
        updateSpy = spy(() => Promise.resolve());
        stub(UserMock, "findOne").callsFake(async () => ({
          get: () => false,
          update: updateSpy,
          resetPasswordValid: () => true,
        }));

        request(app)
          .put("/")
          .send({
            password: "short",
            resetPasswordToken: "12345",
          })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("sets flash error", () => {
        expect(flashSpy.calledWith("error", match.string)).to.be.true;
      });

      it("returns 302", () => {
        expect(response.statusCode).to.eq(302);
      });

      it("does not update password", () => {
        expect(updateSpy.callCount).to.eq(0);
      });
    });

    describe("when user submits password that is too common", () => {
      let response: Response;
      let updateSpy: SinonSpy;
      beforeEach((done) => {
        updateSpy = spy(() => Promise.resolve());
        stub(UserMock, "findOne").callsFake(async () => ({
          get: () => false,
          update: updateSpy,
          resetPasswordValid: () => true,
        }));

        request(app)
          .put("/")
          .send({
            password: "password",
            resetPasswordToken: "12345",
          })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("sets flash error", () => {
        expect(flashSpy.calledWith("error", match.string)).to.be.true;
      });

      it("returns 302", () => {
        expect(response.statusCode).to.eq(302);
      });

      it("does not update password", () => {
        expect(updateSpy.callCount).to.eq(0);
      });
    });

    describe("when user has valid reset token", () => {
      let updateSpy: SinonSpy;
      beforeEach(() => {
        updateSpy = spy(() => Promise.resolve());
        stub(UserMock, "findOne").callsFake(async () => ({
          get: () => false,
          update: updateSpy,
          resetPasswordValid: () => true,
        }));

        app = makeApp({
          "../helpers/getUserPasswordUpdates": mockEsmodule({
            default: () =>
              Promise.resolve({
                encryptedPassword: "drowssap taerg a",
                resetPasswordToken: null,
                resetPasswordSentAt: null,
                confirmedAt: "some date",
              }),
          }),
        });

        return request(app).put("/").send({
          password: "a great password",
          resetPasswordToken: "12345",
        });
      });

      it("updates user", () => {
        expect(
          updateSpy.calledWith({
            encryptedPassword: "drowssap taerg a",
            resetPasswordToken: null,
            resetPasswordSentAt: null,
            confirmedAt: "some date",
          })
        ).to.be.true;
      });
    });
  });

  describe("GET /edit", () => {
    describe("when user does not exist", () => {
      let response: Response;
      beforeEach((done) => {
        stub(UserMock, "findOne").callsFake(async () => null);

        request(app)
          .get("/edit")
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 302", () => {
        expect(response.statusCode).to.eq(302);
      });

      it("redirects to password reset request page", () => {
        expect(response.headers.location).to.eq("/password/new");
      });
    });

    describe("when user does not have valid reset password token", () => {
      let response: Response;
      beforeEach((done) => {
        stub(UserMock, "findOne").callsFake(async () => ({
          resetPasswordValid: () => false,
        }));

        request(app)
          .get("/edit")
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 302", () => {
        expect(response.statusCode).to.eq(302);
      });

      it("redirects to password reset request page", () => {
        expect(response.headers.location).to.eq("/password/new");
      });
    });
  });
});
