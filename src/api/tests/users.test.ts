/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from "chai";
import { SinonSpy, SinonStub, match, spy, stub } from "sinon";
import bodyParser from "body-parser";
import { Response } from "superagent";
import request from "supertest";
import express, { Application, RequestHandler } from "express";
import proxyquire from "proxyquire";
import SequelizeMock from "sequelize-mock";
import hasRoleHelper from "../../helpers/hasRole";
import { Role, Team, User } from "../../interfaces";
import mockEsmodule from "../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe("api/team/users", () => {
  let app: Application;
  let checkTeamRoleSpy: SinonSpy;
  let InvitationMock: SequelizeMockObject;
  let RoleMock: SequelizeMockObject;
  let UserMock: SequelizeMockObject;
  let loggedInSpy: SinonSpy;
  let makeApp: (deps?: any, middleware?: RequestHandler) => Application;
  let broadcastSpy: SinonSpy;
  let team: Team;
  let user: User;

  beforeEach(() => {
    InvitationMock = dbMock.define("invitation", {});
    UserMock = dbMock.define("user", {});
    RoleMock = dbMock.define("role", {});

    team = {
      id: 77,
      get: function get<K extends keyof Team>(prop: K) {
        return this[prop];
      },
    } as Team;
    checkTeamRoleSpy = spy(
      (): RequestHandler => (req, res, next) => {
        req.team = team; // eslint-disable-line no-param-reassign
        next();
      }
    );

    user = {
      get: function get<K extends keyof User>(prop: K) {
        return this[prop];
      },
      id: 231,
    } as User;
    loggedInSpy = spy((req, res, next) => {
      req.user = user; // eslint-disable-line no-param-reassign
      next();
    });

    broadcastSpy = spy();

    makeApp = (deps) => {
      const usersApi = proxyquireStrict("../team/users", {
        "../../db": mockEsmodule({
          Invitation: InvitationMock,
          Role: RoleMock,
          User: UserMock,
        }),
        "../helpers/loggedIn": mockEsmodule({
          default: loggedInSpy,
        }),
        "../helpers/checkTeamRole": mockEsmodule({
          default: checkTeamRoleSpy,
        }),
        ...deps,
      }).default;

      const server = express();
      server.use(bodyParser.json());
      server.use((req, res, next) => {
        req.broadcast = broadcastSpy;
        next();
      });
      server.use("/", usersApi());
      return server;
    };

    app = makeApp();
  });

  describe("GET /", () => {
    beforeEach(() => {
      app = makeApp({
        "../../helpers/hasRole": mockEsmodule({
          default: () => false,
        }),
      });
    });

    describe("before query", () => {
      beforeEach(() => request(app).get("/"));

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it("checks for team role", () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe("query", () => {
      let scopeSpy: SinonSpy;
      beforeEach(() => {
        scopeSpy = spy(UserMock, "scope");
      });

      describe("as guest", () => {
        beforeEach(() => request(app).get("/"));

        it("does not pass extra attributes", () => {
          expect(
            scopeSpy.calledWith({
              method: [match.any, match.any, undefined],
            })
          ).to.be.true;
        });
      });

      describe("as member or owner", () => {
        beforeEach(() => {
          app = makeApp({
            "../../helpers/hasRole": mockEsmodule({
              default: () => true,
            }),
          });
          return request(app).get("/");
        });

        it("passes extra attributes", () => {
          expect(
            scopeSpy.calledWith({
              method: [match.any, match.any, match.array],
            })
          ).to.be.true;
        });
      });
    });

    describe("success", () => {
      let response: Response;
      beforeEach((done) => {
        request(app)
          .get("/")
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 200", () => {
        expect(response.statusCode).to.eq(200);
      });

      it("returns json with decision", () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).not.to.be.null;
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
          "../../db": mockEsmodule({
            User: {
              scope: stub().throws("Oh No"),
            },
          }),
        });

        request(app)
          .get("/")
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

  describe("POST /", () => {
    let sendMailSpy: SinonSpy;
    beforeEach(() => {
      sendMailSpy = spy(() => Promise.resolve());
    });

    describe("before query", () => {
      beforeEach(() => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
        });
        return request(app).post("/");
      });

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it("checks for team role", () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe("when adding disallowed type", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => false,
          }),
        });
        request(app)
          .post("/")
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 403", () => {
        expect(response.statusCode).to.eq(403);
      });

      it("returns json with error message", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("when allowed", () => {
      let findOneSpy: SinonSpy;
      beforeEach(() => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
        });
        findOneSpy = spy(UserMock, "findOne");
        return request(app).post("/").send({ email: "foo@bar.com" });
      });

      it("looks for existing user", () => {
        expect(
          findOneSpy.calledWith({
            where: { email: "foo@bar.com" },
            include: match.any,
          })
        ).to.be.true;
      });
    });

    describe("when user exists and has many roles", () => {
      let response: Response;
      beforeEach((done) => {
        stub(UserMock, "findOne").callsFake(() =>
          Promise.resolve({
            id: 2,
            roles: [{}, {}, {}, {}, {}],
          })
        );
        app = makeApp({
          "../../constants": mockEsmodule({
            TEAM_LIMIT: 5,
          }),
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
        });
        request(app)
          .post("/")
          .send({ email: "foo@bar.com", type: "member" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 403", () => {
        expect(response.statusCode).to.eq(403);
      });

      it("returns json with error", () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("when user exists", () => {
      beforeEach(() => {
        stub(UserMock, "findOne").callsFake(() =>
          Promise.resolve({
            id: 2,
            roles: [],
          })
        );
      });

      describe("but is already on team", () => {
        let response: Response;
        beforeEach((done) => {
          app = makeApp({
            "../../helpers/hasRole": mockEsmodule({
              default: () => true,
            }),
          });
          request(app)
            .post("/")
            .send({ email: "foo@bar.com", type: "member" })
            .then((r) => {
              response = r;
              done();
            });
        });

        it("returns 409", () => {
          expect(response.statusCode).to.eq(409);
        });

        it("returns json with error", () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a("string");
        });
      });

      describe("and is not on team", () => {
        let createSpy: SinonSpy;
        beforeEach(() => {
          app = makeApp({
            "../../helpers/hasRole": mockEsmodule({
              default: stub()
                .onFirstCall()
                .returns(true)
                .onSecondCall()
                .returns(true)
                .onThirdCall()
                .returns(false),
            }),
            "../../mailers/transporter": mockEsmodule({
              default: {
                sendMail: sendMailSpy,
              },
            }),
          });
          createSpy = spy(RoleMock, "create");
          return request(app)
            .post("/")
            .send({ email: "foo@bar.com", type: "member" });
        });

        it("creates team role for user", () => {
          expect(
            createSpy.calledWith({
              teamId: 77,
              userId: 2,
              type: "member",
            })
          ).to.be.true;
        });

        it("calls sendMail", () => {
          expect(sendMailSpy.callCount).to.eq(1);
        });
      });
    });

    describe("when user does not exist", () => {
      let createStub: SinonStub;
      let destroyStub: SinonStub;
      let findOneStub: SinonStub;
      beforeEach(() => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
          "../../mailers/transporter": mockEsmodule({
            default: {
              sendMail: sendMailSpy,
            },
          }),
        });
        findOneStub = stub(UserMock, "findOne").callsFake(() =>
          Promise.resolve(null)
        );
        createStub = stub(UserMock, "create").callsFake(() =>
          Promise.resolve({
            id: 2,
          })
        );
        destroyStub = stub(InvitationMock, "destroy").callsFake(() =>
          Promise.resolve()
        );
        return request(app)
          .post("/")
          .send({ email: "foo@bar.com", name: "Jeffrey", type: "member" });
      });

      it("creates user", () => {
        expect(
          createStub.calledWith({
            email: "foo@bar.com",
            name: "Jeffrey",
            resetPasswordToken: match.string,
            resetPasswordSentAt: match.date,
            roles: [
              {
                teamId: 77,
                type: "member",
              },
            ],
          })
        ).to.be.true;
      });

      it("destroys any invitations that match email", () => {
        expect(
          destroyStub.calledWith({
            where: {
              email: "foo@bar.com",
            },
          })
        ).to.be.true;
      });

      it("calls sendMail", () => {
        expect(sendMailSpy.callCount).to.eq(1);
      });

      it("looks for user again", () => {
        expect(
          findOneStub.calledWith({
            where: {
              id: 2,
            },
          })
        ).to.be.true;
      });
    });

    describe("success", () => {
      let userToCreate: Partial<User>;
      let response: Response;
      beforeEach((done) => {
        userToCreate = { id: 2 };
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
          "../../mailers/transporter": mockEsmodule({
            default: {
              sendMail: sendMailSpy,
            },
          }),
        });
        stub(UserMock, "findOne")
          .onFirstCall()
          .callsFake(() => Promise.resolve(null))
          .onSecondCall()
          .callsFake(() => Promise.resolve(userToCreate));
        stub(UserMock, "create").callsFake(() => Promise.resolve(userToCreate));
        request(app)
          .post("/")
          .send({ email: "foo@bar.com", name: "Jeffrey", type: "member" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 201", () => {
        expect(response.statusCode).to.eq(201);
      });

      it("returns json with user", () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).to.deep.eq(userToCreate);
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/hasRole": mockEsmodule({
            default: () => true,
          }),
        });
        stub(UserMock, "findOne").throws("Oh No");

        request(app)
          .post("/")
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

  describe("PATCH /:id", () => {
    let hasRole: typeof hasRoleHelper;
    beforeEach(() => {
      hasRole = mockEsmodule({
        default: () => true,
      });

      app = makeApp({
        "../../helpers/hasRole": hasRole,
      });
    });

    describe("before query", () => {
      beforeEach(() => request(app).patch("/1"));

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it("checks for team role of member or greater", () => {
        expect(checkTeamRoleSpy.calledWith("member")).to.be.true;
      });
    });

    describe("when patching self", () => {
      let getRoleSpy: SinonSpy;
      let path: string;
      beforeEach(() => {
        getRoleSpy = spy();
        app = makeApp({
          "../../helpers/hasRole": hasRole,
          "../../helpers/getRole": mockEsmodule({
            default: getRoleSpy,
          }),
        });
        path = `/${user.id}`;
        return request(app).patch(path).send({ type: "member" });
      });

      it("gets user's role on team", () => {
        expect(getRoleSpy.firstCall.args).to.deep.eq([user, team]);
      });
    });

    describe("when owner is changing self", () => {
      let role: Role;
      let path: string;
      beforeEach(() => {
        role = {
          userId: user.id,
          teamId: team.id,
          type: "owner",
        } as Role;
        role.update = spy();
        path = `/${user.id}`;
        app = makeApp({
          "../../helpers/hasRole": hasRole,
          "../../helpers/getRole": mockEsmodule({
            default: spy(() => role),
          }),
        });
      });

      describe("to member", () => {
        let payload: Partial<Role>;
        beforeEach(() => {
          payload = { type: "member" };
        });

        describe("but there are no other owners", () => {
          let findAllStub: SinonStub;
          let response: Response;
          beforeEach((done) => {
            findAllStub = stub(RoleMock, "findAll").callsFake(() =>
              Promise.resolve([
                role,
                {
                  type: "member",
                  userId: 2,
                },
              ])
            );
            request(app)
              .patch(path)
              .send(payload)
              .then((r) => {
                response = r;
                done();
              });
          });

          it("finds all roles", () => {
            expect(findAllStub.calledWith({ where: { teamId: team.id } })).to.be
              .true;
          });

          it("returns 403", () => {
            expect(response.statusCode).to.eq(403);
          });

          it("returns json with error", () => {
            expect(response.body.error).to.be.true;
            expect(response.body.data.message).to.be.a("string");
          });
        });

        describe("and there are other owners", () => {
          beforeEach(() => {
            stub(RoleMock, "findAll").callsFake(() =>
              Promise.resolve([
                role,
                {
                  type: "owner",
                  userId: 2,
                },
              ])
            );
            return request(app).patch(path).send(payload);
          });

          it("updates role", () => {
            expect((role.update as SinonSpy).calledWith({ type: "member" })).to
              .be.true;
          });
        });
      });
    });

    describe("when patching other", () => {
      let findOneSpy: SinonSpy;
      beforeEach(() => {
        findOneSpy = spy(RoleMock, "findOne");
        return request(app).patch("/2").send({ type: "member" });
      });

      it("queries role on team", () => {
        expect(
          findOneSpy.calledWith({
            where: {
              teamId: team.id,
              userId: 2,
            },
          })
        ).to.be.true;
      });
    });

    describe("when owner is changing other", () => {
      let currentUserRole: Role;
      let otherUserId: number;
      let path: string;
      let role: Role;
      beforeEach(() => {
        currentUserRole = {
          userId: user.id,
          teamId: team.id,
          type: "owner",
        } as Role;
        role = {
          userId: otherUserId,
          teamId: team.id,
        } as Role;
        role.update = spy();
        otherUserId = 2;
        path = `/${otherUserId}`;
        app = makeApp({
          "../../helpers/hasRole": hasRole,
          "../../helpers/getRole": mockEsmodule({
            default: spy(() => currentUserRole),
          }),
        });
      });

      describe("owner", () => {
        beforeEach(() => {
          role.type = "owner";
          stub(RoleMock, "findOne").callsFake(() => Promise.resolve(role));
          return request(app).patch(path).send({ type: "member" });
        });

        it("updates role", () => {
          expect((role.update as SinonSpy).calledWith({ type: "member" })).to.be
            .true;
        });
      });

      describe("member", () => {
        beforeEach(() => {
          role.type = "member";
          stub(RoleMock, "findOne").callsFake(() => Promise.resolve(role));
          return request(app).patch(path).send({ type: "owner" });
        });

        it("updates role", () => {
          expect((role.update as SinonSpy).calledWith({ type: "owner" })).to.be
            .true;
        });
      });

      describe("guest", () => {
        beforeEach(() => {
          role.type = "guest";
          stub(RoleMock, "findOne").callsFake(() => Promise.resolve(role));
          return request(app).patch(path).send({ type: "owner" });
        });

        it("updates role", () => {
          expect((role.update as SinonSpy).calledWith({ type: "owner" })).to.be
            .true;
        });
      });
    });

    describe("when member is changing other", () => {
      let currentUserRole: Role;
      let otherUserId: number;
      let path: string;
      let role: Role;
      beforeEach(() => {
        currentUserRole = {
          userId: user.id,
          teamId: team.id,
          type: "member",
        } as Role;
        role = {
          userId: otherUserId,
          teamId: team.id,
        } as Role;
        role.update = spy();
        otherUserId = 2;
        path = `/${otherUserId}`;
        app = makeApp({
          "../../helpers/hasRole": hasRole,
          "../../helpers/getRole": mockEsmodule({
            default: spy(() => currentUserRole),
          }),
        });
      });

      describe("owner", () => {
        let response: Response;
        beforeEach((done) => {
          role.type = "owner";
          stub(RoleMock, "findOne").callsFake(() => Promise.resolve(role));
          request(app)
            .patch(path)
            .send({ type: "member" })
            .then((r) => {
              response = r;
              done();
            });
        });

        it("returns 403", () => {
          expect(response.statusCode).to.eq(403);
        });

        it("returns json with error", () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a("string");
        });
      });

      describe("member", () => {
        let response: Response;
        beforeEach((done) => {
          role.type = "member";
          stub(RoleMock, "findOne").callsFake(() => Promise.resolve(role));
          request(app)
            .patch(path)
            .send({ type: "member" })
            .then((r) => {
              response = r;
              done();
            });
        });

        it("returns 403", () => {
          expect(response.statusCode).to.eq(403);
        });
      });

      describe("guest", () => {
        beforeEach(() => {
          role.type = "guest";
          stub(RoleMock, "findOne").callsFake(() => Promise.resolve(role));
        });

        describe("to member", () => {
          beforeEach(() => request(app).patch(path).send({ type: "member" }));

          it("updates role", () => {
            expect((role.update as SinonSpy).calledWith({ type: "member" })).to
              .be.true;
          });
        });

        describe("to owner", () => {
          let response: Response;
          beforeEach((done) => {
            request(app)
              .patch(path)
              .send({ type: "owner" })
              .then((r) => {
                response = r;
                done();
              });
          });

          it("returns 403", () => {
            expect(response.statusCode).to.eq(403);
          });
        });
      });
    });

    describe("when no user is found", () => {
      let response: Response;
      beforeEach((done) => {
        stub(RoleMock, "findOne").callsFake(() => Promise.resolve(null));
        request(app)
          .patch("/2")
          .send({ type: "member" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 404", () => {
        expect(response.statusCode).to.eq(404);
      });

      it("returns json with error", () => {
        expect(response.body.error).to.eq(true);
        expect(response.body.data.message).to.be.a("string");
      });
    });

    describe("success", () => {
      let response: Response;
      let currentUserRole: Role;
      let userToChange: User;
      beforeEach((done) => {
        currentUserRole = {
          userId: user.id,
          teamId: team.id,
          type: "member",
        } as Role;
        userToChange = {
          id: 2,
        } as User;
        stub(RoleMock, "findOne").callsFake(() =>
          Promise.resolve({
            update: () => Promise.resolve(),
            userId: userToChange.id,
            teamId: team.id,
            type: "guest",
          })
        );
        stub(UserMock, "findOne").callsFake(() =>
          Promise.resolve(userToChange)
        );
        app = makeApp({
          "../../helpers/hasRole": hasRole,
          "../../helpers/getRole": mockEsmodule({
            default: spy(() => currentUserRole),
          }),
        });

        request(app)
          .patch("/2")
          .send({ type: "member" })
          .then((r) => {
            response = r;
            done();
          });
      });

      it("returns 200", () => {
        expect(response.statusCode).to.eq(200);
      });

      it("returns json with user", () => {
        expect(response.body.error).to.be.false;
        expect(response.body.data).to.deep.eq(userToChange);
      });
    });

    describe("failure", () => {
      let response: Response;
      beforeEach((done) => {
        app = makeApp({
          "../../helpers/hasRole": hasRole,
          "../../db": mockEsmodule({
            Role: {
              findOne: stub().throws("Oh No"),
            },
          }),
        });

        request(app)
          .patch("/1")
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

  describe("DELETE /:id", () => {
    describe("before query", () => {
      beforeEach(() => request(app).delete("/1"));

      it("checks for login", () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it("checks for team role of member or greater", () => {
        expect(checkTeamRoleSpy.calledWith("member")).to.be.true;
      });
    });

    describe("success", () => {
      let response: Response;
      let roleToDestroy: Role;
      let currentUserRole: Role;
      let userToDelete: User;
      beforeEach((done) => {
        currentUserRole = {
          userId: user.id,
          teamId: team.id,
          type: "member",
        } as Role;
        userToDelete = {
          id: 2,
        } as User;
        roleToDestroy = {
          userId: userToDelete.id,
          teamId: team.id,
          type: "guest",
        } as Role;
        roleToDestroy.destroy = spy(() => Promise.resolve());
        stub(RoleMock, "findOne").callsFake(() =>
          Promise.resolve(roleToDestroy)
        );
        stub(UserMock, "findOne").callsFake(() =>
          Promise.resolve(userToDelete)
        );
        app = makeApp({
          "../../helpers/getRole": mockEsmodule({
            default: spy(() => currentUserRole),
          }),
        });

        request(app)
          .delete(`/${userToDelete.id}`)
          .then((r) => {
            response = r;
            done();
          });
      });

      it("deletes role", () => {
        expect((roleToDestroy.destroy as SinonSpy).callCount).to.eq(1);
      });

      it("returns 204", () => {
        expect(response.statusCode).to.eq(204);
      });
    });
  });
});
