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
import { MakeApp, User } from "../../interfaces";

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe("middlewares/users", () => {
  let app: Application;
  let createSpy: SinonSpy;
  let destroySpy: SinonSpy;
  let makeApp: MakeApp;
  let sendMailSpy: SinonSpy;
  let InvitationMock: SequelizeMockObject;
  let UserMock: SequelizeMockObject;
  let flashSpy: SinonSpy;

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
        "../db": mockEsmodule({
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
          } as User;
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
          } as User;
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
      let response: Response;
      beforeEach((done) => {
        app = makeApp({}, (req, res, next) => {
          req.user = {
            get: () => true,
          } as User;
          next();
        });

        createSpy.restore();
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
