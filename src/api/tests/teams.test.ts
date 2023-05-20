/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { match, spy, SinonSpy, stub } from "sinon";
import bodyParser from "body-parser";
import { HTTPError } from "superagent";
import request, { Response } from "supertest";
import express, { RequestHandler } from "express";
import session, { Session } from "express-session";
import proxyquire from "proxyquire";
import SequelizeMock from "sequelize-mock";
import mockEsmodule from "../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe("api/main/teams", () => {
  let app: Express.Application;
  let RoleMock: SequelizeMockObject;
  let TeamMock: SequelizeMockObject;
  let UserMock: SequelizeMockObject;
  let loggedInSpy: SinonSpy;
  let makeApp: (deps?: any, middleware?: RequestHandler) => Express.Application;
  let sendMailSpy: SinonSpy;

  beforeEach(() => {
    TeamMock = dbMock.define("team", {});
    TeamMock.findAllForUser = () => Promise.resolve([]);
    RoleMock = dbMock.define("role", {});
    UserMock = dbMock.define("user", {});
    UserMock.hasMany(RoleMock);

    loggedInSpy = spy((req, res, next) => {
      req.user = {
        // eslint-disable-line no-param-reassign
        get: () => undefined,
        id: 231,
        $get: () => [],
        roles: [],
      };
      next();
    });

    sendMailSpy = spy(() => Promise.resolve());

    makeApp = (deps, middleware): Express.Application => {
      const teamsApi = proxyquireStrict("../main/teams", {
        "../../db": mockEsmodule({
          Team: TeamMock,
          Role: RoleMock,
          User: UserMock,
        }),
        "../helpers/loggedIn": mockEsmodule({
          default: loggedInSpy,
        }),
        "../../mailers/transporter": mockEsmodule({
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
        if (middleware) {
          middleware(req, res, next);
        } else {
          next();
        }
      });
      server.use("/", teamsApi());
      return server;
    };

    app = makeApp();
  });

  describe("GET /", () => {
    describe("before query", () => {
      beforeEach(() => request(app).get("/").send());

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });
    });

    describe("success", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .get("/")
          .send()
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 200", () => {
        expect(response.statusCode).to.eq(200);
      });

      it("returns json with teams", () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).not.to.be.null;
      });
    });
  });

  describe("POST /", () => {
    describe("before query", () => {
      beforeEach(() =>
        request(app).post("/").send({ name: "Something", slug: "something" })
      );

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });
    });

    describe("exceeds team limit", () => {
      let createSpy: SinonSpy;
      let response: Response;
      beforeEach((done) => {
        createSpy = spy(TeamMock, "create");
        loggedInSpy = spy((req, res, next) => {
          req.user = {
            // eslint-disable-line no-param-reassign
            id: 231,
            $get: () => [{}, {}, {}, {}, {}],
            roles: [{}, {}, {}, {}, {}],
          };
          next();
        });
        app = makeApp({
          "../../constants": mockEsmodule({
            TEAM_LIMIT: 5,
          }),
        });
        request(app)
          .post("/")
          .send({ name: "Something", slug: "something" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("does not create team", () => {
        expect(createSpy.callCount).to.eq(0);
      });

      it("returns 403", () => {
        expect(response.statusCode).to.eq(403);
      });

      it("returns json with error message", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("reserved slug check", () => {
      let createSpy: SinonSpy;
      let response: Response;
      beforeEach((done) => {
        createSpy = spy(TeamMock, "create");
        request(app)
          .post("/")
          .send({ name: "World Wide What", slug: "www" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("does not create team", () => {
        expect(createSpy.callCount).to.eq(0);
      });

      it("returns 409", () => {
        expect(response.statusCode).to.eq(409);
      });

      it("returns json with error message", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("existing slug check", () => {
      let response: Response;
      beforeEach((done) => {
        stub(TeamMock, "create").callsFake(() => {
          const e = new Error();
          e.name = "SequelizeUniqueConstraintError";
          return Promise.reject(e);
        });

        request(app)
          .post("/")
          .send({ name: "Existing Team", slug: "existing" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 409", () => {
        expect(response.statusCode).to.eq(409);
      });

      it("returns json with error message", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("invalid slug", () => {
      let createSpy: SinonSpy;
      let response: Response;
      beforeEach(() => {
        createSpy = spy(TeamMock, "create");
      });

      describe("with only numbers", () => {
        beforeEach((done) => {
          request(app)
            .post("/")
            .send({ name: "Numbers", slug: "33" })
            .then((r) => {
              response = r;
              done();
            });
        });

        it("does not create team", () => {
          expect(createSpy.callCount).to.eq(0);
        });

        it("returns 422", () => {
          expect(response.statusCode).to.eq(422);
        });

        it("returns json with error message", () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a("string");
        });
      });

      describe("with dashes at beginning", () => {
        beforeEach((done) => {
          request(app)
            .post("/")
            .send({ name: "Beginning Dash", slug: "-abc" })
            .then((r) => {
              response = r;
              done();
            });
        });

        it("does not create team", () => {
          expect(createSpy.callCount).to.eq(0);
        });

        it("returns 422", () => {
          expect(response.statusCode).to.eq(422);
        });

        it("returns json with error message", () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a("string");
        });
      });

      describe("with dashes at end", () => {
        beforeEach((done) => {
          request(app)
            .post("/")
            .send({ name: "Ending Dash", slug: "abc-" })
            .then((r) => {
              response = r;
              done();
            });
        });

        it("does not create team", () => {
          expect(createSpy.callCount).to.eq(0);
        });

        it("returns 422", () => {
          expect(response.statusCode).to.eq(422);
        });

        it("returns json with error message", () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a("string");
        });
      });
    });

    describe("queries", () => {
      let createSpy: SinonSpy;
      beforeEach(() => {
        createSpy = spy(TeamMock, "create");
        return request(app).post("/").send({
          address: "77 Battery",
          lat: 123,
          lng: 321,
          name: "Lab Zero",
          slug: "labzero",
        });
      });

      it("creates new team", () => {
        expect(
          createSpy.calledWith({
            address: "77 Battery",
            lat: 123,
            lng: 321,
            name: "Lab Zero",
            slug: "labzero",
            roles: [
              {
                userId: 231,
                type: "owner",
              },
            ],
          })
        ).to.be.true;
      });
    });

    describe("success", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .post("/")
          .send({ name: "Lab Zero", slug: "333-labzero-333" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 201", () => {
        expect(response.statusCode).to.eq(201);
      });

      it("returns json with team", () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).not.to.be.null;
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../db": mockEsmodule({
            Team: {
              create: stub().throws(),
              destroy: TeamMock.destroy,
              scope: TeamMock.scope,
            },
          }),
        });
        request(app)
          .post("/")
          .send({ name: "blah", slug: "blah" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns error", () => {
        expect((response.error as HTTPError).text).to.exist;
      });
    });
  });

  describe("DELETE /:id", () => {
    let checkTeamRoleSpy: SinonSpy;
    beforeEach(() => {
      checkTeamRoleSpy = spy((): RequestHandler => (req, res, next) => next());

      app = makeApp({
        "../helpers/checkTeamRole": checkTeamRoleSpy,
      });
    });

    describe("before deletion", () => {
      let findOneSpy: SinonSpy;
      beforeEach(() => {
        findOneSpy = spy(TeamMock, "findOne");

        return request(app).delete("/1");
      });

      it("finds team", () => {
        expect(findOneSpy.calledWith({ where: { id: 1 } })).to.be.true;
      });

      it("checks for owner role", () => {
        expect(checkTeamRoleSpy.calledWith("owner")).to.be.true;
      });
    });

    describe("query", () => {
      let destroySpy: SinonSpy;
      beforeEach(() => {
        destroySpy = spy();
        stub(TeamMock, "findOne").callsFake(() =>
          Promise.resolve({
            destroy: destroySpy,
          })
        );

        return request(app).delete("/1");
      });

      it("deletes team", () => {
        expect(destroySpy.callCount).to.eq(1);
      });
    });

    describe("success", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .delete("/1")
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 204", () => {
        expect(response.statusCode).to.eq(204);
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        stub(TeamMock, "findOne").callsFake(() =>
          Promise.resolve({
            destroy: stub().throws("Oh No"),
          })
        );
        app = makeApp({
          "../helpers/checkTeamRole": checkTeamRoleSpy,
        });
        request(app)
          .delete("/1")
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns error", () => {
        expect((response.error as HTTPError).text).to.contain("Oh No");
      });
    });
  });

  describe("PATCH /:id", () => {
    let checkTeamRoleSpy: SinonSpy;
    beforeEach(() => {
      checkTeamRoleSpy = spy((req, res, next) => next());

      app = makeApp({
        "../helpers/checkTeamRole": () => checkTeamRoleSpy,
      });
    });

    describe("before updating", () => {
      let findOneSpy: SinonSpy;
      beforeEach(() => {
        findOneSpy = spy(TeamMock, "findOne");

        return request(app).patch("/1");
      });

      it("finds team", () => {
        expect(findOneSpy.calledWith({ where: { id: 1 } })).to.be.true;
      });

      it("checks for team role", () => {
        expect(checkTeamRoleSpy.callCount).to.eq(1);
      });
    });

    describe("without valid parameters", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .patch("/1")
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
      let updateSpy: SinonSpy;
      beforeEach(() => {
        updateSpy = spy();
        stub(TeamMock, "findOne").callsFake(() =>
          Promise.resolve({
            get: () => undefined,
            update: updateSpy,
          })
        );

        return request(app).patch("/1").send({ defaultZoom: 15, id: 123 });
      });

      it("updates team", () => {
        expect(updateSpy.callCount).to.eq(1);
      });
    });

    describe("reserved slug check", () => {
      let updateSpy: SinonSpy;
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
          "../helpers/checkTeamRole": mockEsmodule({
            default: () => checkTeamRoleSpy,
          }),
        });

        updateSpy = spy();
        stub(TeamMock, "findOne").callsFake(() =>
          Promise.resolve({
            get: () => undefined,
            update: updateSpy,
          })
        );

        request(app)
          .patch("/1")
          .send({ name: "World Wide What", slug: "www" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("does not update team", () => {
        expect(updateSpy.callCount).to.eq(0);
      });

      it("returns 409", () => {
        expect(response.statusCode).to.eq(409);
      });

      it("returns json with error message", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("existing slug check", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
          "../helpers/checkTeamRole": mockEsmodule({
            default: () => checkTeamRoleSpy,
          }),
        });

        stub(TeamMock, "findOne").callsFake(() =>
          Promise.resolve({
            get: () => undefined,
            update: () => {
              const e = new Error();
              e.name = "SequelizeUniqueConstraintError";
              return Promise.reject(e);
            },
          })
        );

        request(app)
          .patch("/1")
          .send({ name: "Existing Team", slug: "existing" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 409", () => {
        expect(response.statusCode).to.eq(409);
      });

      it("returns json with error message", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("success", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .patch("/1")
          .send({ defaultZoom: 15 })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 200", () => {
        expect(response.statusCode).to.eq(200);
      });

      it("returns json with team", () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).to.be.an("object");
      });
    });

    describe("if team has changed", () => {
      let flashSpy: SinonSpy;
      beforeEach(() => {
        flashSpy = spy();

        app = makeApp(
          {
            "../../helpers/hasRole": mockEsmodule({
              default: () => true,
            }),
            "../helpers/checkTeamRole": mockEsmodule({
              default: () => checkTeamRoleSpy,
            }),
          },
          (req, res, next) => {
            req.flash = flashSpy;
            stub(req.session, "save").callsFake(function save(
              this: Session,
              cb
            ) {
              cb!({});
              return this;
            });
            next();
          }
        );

        return request(app).patch("/1").send({ slug: "new-slug" });
      });

      it("flashes a success message", () => {
        expect(flashSpy.calledWith("success", match.string)).to.be.true;
      });

      it("sends mail", () => {
        expect(sendMailSpy.callCount).to.eq(1);
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        stub(TeamMock, "findOne").callsFake(() =>
          Promise.resolve({
            get: () => undefined,
            update: stub().throws("Oh No"),
          })
        );
        request(app)
          .patch("/1")
          .send({ defaultZoom: 15 })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns error", () => {
        expect((response.error as HTTPError).text).to.contain("Oh No");
      });
    });
  });
});
