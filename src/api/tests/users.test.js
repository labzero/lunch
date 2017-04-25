/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import { match, spy, stub } from 'sinon';
import bodyParser from 'body-parser';
import request from 'supertest';
import express from 'express';
import proxyquire from 'proxyquire';
import SequelizeMock from 'sequelize-mock';
import mockEsmodule from '../../../test/mockEsmodule';

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe('api/team/users', () => {
  let app;
  let checkTeamRoleSpy;
  let InvitationMock;
  let RoleMock;
  let UserMock;
  let loggedInSpy;
  let makeApp;
  let broadcastSpy;
  let team;
  let user;

  beforeEach(() => {
    InvitationMock = dbMock.define('invitation', {});
    UserMock = dbMock.define('user', {});
    RoleMock = dbMock.define('role', {});

    team = {
      id: 77,
      get: function get(prop) {
        return this[prop];
      },
      stub: 'Lab Zero'
    };
    checkTeamRoleSpy = spy(() => (req, res, next) => {
      req.team = team; // eslint-disable-line no-param-reassign
      next();
    });

    user = {
      get: function get(prop) {
        return this[prop];
      },
      id: 231
    };
    loggedInSpy = spy((req, res, next) => {
      req.user = user; // eslint-disable-line no-param-reassign
      next();
    });

    broadcastSpy = spy();

    makeApp = deps => {
      const usersApi = proxyquireStrict('../team/users', {
        '../../models': mockEsmodule({
          Invitation: InvitationMock,
          Role: RoleMock,
          User: UserMock,
        }),
        '../helpers/loggedIn': mockEsmodule({
          default: loggedInSpy
        }),
        '../helpers/checkTeamRole': mockEsmodule({
          default: checkTeamRoleSpy
        }),
        ...deps
      }).default;

      const server = express();
      server.use(bodyParser.json());
      server.use((req, res, next) => {
        req.wss = { // eslint-disable-line no-param-reassign
          broadcast: broadcastSpy
        };
        next();
      });
      server.use('/', usersApi());
      return server;
    };

    app = makeApp();
  });

  describe('GET /', () => {
    beforeEach(() => {
      app = makeApp({
        '../../helpers/hasRole': mockEsmodule({
          default: () => false
        })
      });
    });

    describe('before query', () => {
      beforeEach(() =>
        request(app).get('/')
      );

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role', () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe('query', () => {
      let scopeSpy;
      beforeEach(() => {
        scopeSpy = spy(UserMock, 'scope');
      });

      describe('as guest', () => {
        beforeEach(() =>
          request(app).get('/')
        );

        it('does not pass extra attributes', () => {
          expect(scopeSpy.calledWith({
            method: [match.any, match.any, undefined]
          })).to.be.true;
        });
      });

      describe('as member or owner', () => {
        beforeEach(() => {
          app = makeApp({
            '../../helpers/hasRole': mockEsmodule({
              default: () => true
            })
          });
          return request(app).get('/');
        });

        it('passes extra attributes', () => {
          expect(scopeSpy.calledWith({
            method: [match.any, match.any, match.array]
          })).to.be.true;
        });
      });
    });

    describe('success', () => {
      let response;
      beforeEach((done) => {
        request(app).get('/').then(r => {
          response = r;
          done();
        });
      });

      it('returns 200', () => {
        expect(response.statusCode).to.eq(200);
      });

      it('returns json with decision', () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).not.to.be.null;
      });
    });

    describe('failure', () => {
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          }),
          '../../models': mockEsmodule({
            User: {
              scope: stub().throws('Oh No')
            }
          })
        });

        request(app).get('/').then((r) => {
          response = r;
          done();
        });
      });

      it('returns error', () => {
        expect(response.error.text).to.contain('Oh No');
      });
    });
  });

  describe('POST /', () => {
    let sendMailSpy;
    beforeEach(() => {
      sendMailSpy = spy(() => Promise.resolve());
    });

    describe('before query', () => {
      beforeEach(() => {
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          })
        });
        return request(app).post('/');
      });

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role', () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe('when adding disallowed type', () => {
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => false
          })
        });
        request(app).post('/').then(r => {
          response = r;
          done();
        });
      });

      it('returns 403', () => {
        expect(response.statusCode).to.eq(403);
      });

      it('returns json with error message', () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a('string');
      });
    });

    describe('when allowed', () => {
      let findOneSpy;
      beforeEach(() => {
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          })
        });
        findOneSpy = spy(UserMock, 'findOne');
        return request(app).post('/').send({ email: 'foo@bar.com' });
      });

      it('looks for existing user', () => {
        expect(findOneSpy.calledWith({
          where: { email: 'foo@bar.com' },
          include: match.any
        })).to.be.true;
      });
    });

    describe('when user exists and has many roles', () => {
      let response;
      beforeEach((done) => {
        stub(UserMock, 'findOne').callsFake(() => Promise.resolve({
          id: 2,
          roles: [{}, {}, {}, {}, {}]
        }));
        app = makeApp({
          '../../constants': mockEsmodule({
            TEAM_LIMIT: 5
          }),
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          })
        });
        request(app).post('/').send({ email: 'foo@bar.com', type: 'member' }).then(r => {
          response = r;
          done();
        });
      });

      it('returns 403', () => {
        expect(response.statusCode).to.eq(403);
      });

      it('returns json with error', () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a('string');
      });
    });

    describe('when user exists', () => {
      beforeEach(() => {
        stub(UserMock, 'findOne').callsFake(() => Promise.resolve({
          id: 2,
          roles: []
        }));
      });

      describe('but is already on team', () => {
        let response;
        beforeEach((done) => {
          app = makeApp({
            '../../helpers/hasRole': mockEsmodule({
              default: () => true
            })
          });
          request(app).post('/').send({ email: 'foo@bar.com', type: 'member' }).then(r => {
            response = r;
            done();
          });
        });

        it('returns 409', () => {
          expect(response.statusCode).to.eq(409);
        });

        it('returns json with error', () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a('string');
        });
      });

      describe('and is not on team', () => {
        let createSpy;
        beforeEach(() => {
          app = makeApp({
            '../../helpers/hasRole': mockEsmodule({
              default: stub()
                .onFirstCall()
                .returns(true)
                .onSecondCall()
                .returns(true)
                .onThirdCall()
                .returns(false)
            }),
            '../../mailers/transporter': mockEsmodule({
              default: {
                sendMail: sendMailSpy
              }
            })
          });
          createSpy = spy(RoleMock, 'create');
          return request(app).post('/').send({ email: 'foo@bar.com', type: 'member' });
        });

        it('creates team role for user', () => {
          expect(createSpy.calledWith({
            team_id: 77,
            user_id: 2,
            type: 'member'
          })).to.be.true;
        });

        it('calls sendMail', () => {
          expect(sendMailSpy.callCount).to.eq(1);
        });
      });
    });

    describe('when user does not exist', () => {
      let createStub;
      let destroyStub;
      let findOneStub;
      beforeEach(() => {
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          }),
          '../../mailers/transporter': mockEsmodule({
            default: {
              sendMail: sendMailSpy
            }
          })
        });
        findOneStub = stub(UserMock, 'findOne')
          .callsFake(() => Promise.resolve(null));
        createStub = stub(UserMock, 'create')
          .callsFake(() => Promise.resolve({
            id: 2
          }));
        destroyStub = stub(InvitationMock, 'destroy')
          .callsFake(() => Promise.resolve());
        return request(app).post('/').send({ email: 'foo@bar.com', name: 'Jeffrey', type: 'member' });
      });

      it('creates user', () => {
        expect(createStub.calledWith({
          email: 'foo@bar.com',
          name: 'Jeffrey',
          reset_password_token: match.string,
          reset_password_sent_at: match.date,
          roles: [{
            team_id: 77,
            type: 'member'
          }]
        })).to.be.true;
      });

      it('destroys any invitations that match email', () => {
        expect(destroyStub.calledWith({
          where: {
            email: 'foo@bar.com'
          }
        })).to.be.true;
      });

      it('calls sendMail', () => {
        expect(sendMailSpy.callCount).to.eq(1);
      });

      it('looks for user again', () => {
        expect(findOneStub.calledWith({
          where: {
            id: 2
          }
        })).to.be.true;
      });
    });

    describe('success', () => {
      let userToCreate;
      let response;
      beforeEach((done) => {
        userToCreate = { id: 2 };
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          }),
          '../../mailers/transporter': mockEsmodule({
            default: {
              sendMail: sendMailSpy
            }
          })
        });
        stub(UserMock, 'findOne')
          .onFirstCall()
          .callsFake(() => Promise.resolve(null))
          .onSecondCall()
          .callsFake(() => Promise.resolve(userToCreate));
        stub(UserMock, 'create')
          .callsFake(() => Promise.resolve(userToCreate));
        request(app)
          .post('/')
          .send({ email: 'foo@bar.com', name: 'Jeffrey', type: 'member' })
          .then(r => {
            response = r;
            done();
          });
      });

      it('returns 201', () => {
        expect(response.statusCode).to.eq(201);
      });

      it('returns json with user', () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).to.deep.eq(userToCreate);
      });
    });

    describe('failure', () => {
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../../helpers/hasRole': mockEsmodule({
            default: () => true
          }),
        });
        stub(UserMock, 'findOne').throws('Oh No');

        request(app).post('/').then((r) => {
          response = r;
          done();
        });
      });

      it('returns error', () => {
        expect(response.error.text).to.contain('Oh No');
      });
    });
  });

  describe('PATCH /:id', () => {
    let hasRole;
    beforeEach(() => {
      hasRole = mockEsmodule({
        default: () => true
      });

      app = makeApp({
        '../../helpers/hasRole': hasRole
      });
    });

    describe('before query', () => {
      beforeEach(() =>
        request(app).patch('/1')
      );

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role of member or greater', () => {
        expect(checkTeamRoleSpy.calledWith('member')).to.be.true;
      });
    });

    describe('when patching self', () => {
      let getRoleSpy;
      let path;
      beforeEach(() => {
        getRoleSpy = spy();
        app = makeApp({
          '../../helpers/hasRole': hasRole,
          '../../helpers/getRole': mockEsmodule({
            default: getRoleSpy
          })
        });
        path = `/${user.id}`;
        return request(app).patch(path).send({ type: 'member' });
      });

      it('gets user\'s role on team', () => {
        expect(getRoleSpy.firstCall.args).to.deep.eq([user, team]);
      });
    });

    describe('when owner is changing self', () => {
      let role;
      let path;
      beforeEach(() => {
        role = {
          update: spy(),
          user_id: user.id,
          team_id: team.id,
          type: 'owner'
        };
        path = `/${user.id}`;
        app = makeApp({
          '../../helpers/hasRole': hasRole,
          '../../helpers/getRole': mockEsmodule({
            default: spy(() => role)
          })
        });
      });

      describe('to member', () => {
        let payload;
        beforeEach(() => {
          payload = { type: 'member' };
        });

        describe('but there are no other owners', () => {
          let findAllStub;
          let response;
          beforeEach((done) => {
            findAllStub = stub(RoleMock, 'findAll').callsFake(() => Promise.resolve([role, {
              type: 'member',
              user_id: 2
            }]));
            request(app).patch(path).send(payload).then((r) => {
              response = r;
              done();
            });
          });

          it('finds all roles', () => {
            expect(findAllStub.calledWith({ where: { team_id: team.id } })).to.be.true;
          });

          it('returns 403', () => {
            expect(response.statusCode).to.eq(403);
          });

          it('returns json with error', () => {
            expect(response.body.error).to.be.true;
            expect(response.body.data.message).to.be.a('string');
          });
        });

        describe('and there are other owners', () => {
          beforeEach(() => {
            stub(RoleMock, 'findAll').callsFake(() => Promise.resolve([role, {
              type: 'owner',
              user_id: 2
            }]));
            return request(app).patch(path).send(payload);
          });

          it('updates role', () => {
            expect(role.update.calledWith({ type: 'member' })).to.be.true;
          });
        });
      });
    });

    describe('when patching other', () => {
      let findOneSpy;
      beforeEach(() => {
        findOneSpy = spy(RoleMock, 'findOne');
        return request(app).patch('/2').send({ type: 'member' });
      });

      it('queries role on team', () => {
        expect(findOneSpy.calledWith({
          where: {
            team_id: team.id,
            user_id: 2
          }
        })).to.be.true;
      });
    });

    describe('when owner is changing other', () => {
      let currentUserRole;
      let otherUserId;
      let path;
      let role;
      beforeEach(() => {
        currentUserRole = {
          user_id: user.id,
          team_id: team.id,
          type: 'owner'
        };
        role = {
          update: spy(),
          user_id: otherUserId,
          team_id: team.id
        };
        otherUserId = 2;
        path = `/${otherUserId}`;
        app = makeApp({
          '../../helpers/hasRole': hasRole,
          '../../helpers/getRole': mockEsmodule({
            default: spy(() => currentUserRole)
          })
        });
      });

      describe('owner', () => {
        beforeEach(() => {
          role.type = 'owner';
          stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(role));
          return request(app).patch(path).send({ type: 'member' });
        });

        it('updates role', () => {
          expect(role.update.calledWith({ type: 'member' })).to.be.true;
        });
      });

      describe('member', () => {
        beforeEach(() => {
          role.type = 'member';
          stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(role));
          return request(app).patch(path).send({ type: 'owner' });
        });

        it('updates role', () => {
          expect(role.update.calledWith({ type: 'owner' })).to.be.true;
        });
      });

      describe('guest', () => {
        beforeEach(() => {
          role.type = 'guest';
          stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(role));
          return request(app).patch(path).send({ type: 'owner' });
        });

        it('updates role', () => {
          expect(role.update.calledWith({ type: 'owner' })).to.be.true;
        });
      });
    });

    describe('when member is changing other', () => {
      let currentUserRole;
      let otherUserId;
      let path;
      let role;
      beforeEach(() => {
        currentUserRole = {
          user_id: user.id,
          team_id: team.id,
          type: 'member'
        };
        role = {
          update: spy(),
          user_id: otherUserId,
          team_id: team.id
        };
        otherUserId = 2;
        path = `/${otherUserId}`;
        app = makeApp({
          '../../helpers/hasRole': hasRole,
          '../../helpers/getRole': mockEsmodule({
            default: spy(() => currentUserRole)
          })
        });
      });

      describe('owner', () => {
        let response;
        beforeEach((done) => {
          role.type = 'owner';
          stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(role));
          request(app).patch(path).send({ type: 'member' }).then((r) => {
            response = r;
            done();
          });
        });

        it('returns 403', () => {
          expect(response.statusCode).to.eq(403);
        });

        it('returns json with error', () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a('string');
        });
      });

      describe('member', () => {
        let response;
        beforeEach((done) => {
          role.type = 'member';
          stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(role));
          request(app).patch(path).send({ type: 'member' }).then((r) => {
            response = r;
            done();
          });
        });

        it('returns 403', () => {
          expect(response.statusCode).to.eq(403);
        });
      });

      describe('guest', () => {
        beforeEach(() => {
          role.type = 'guest';
          stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(role));
        });

        describe('to member', () => {
          beforeEach(() =>
            request(app).patch(path).send({ type: 'member' })
          );

          it('updates role', () => {
            expect(role.update.calledWith({ type: 'member' })).to.be.true;
          });
        });

        describe('to owner', () => {
          let response;
          beforeEach((done) => {
            request(app).patch(path).send({ type: 'owner' }).then((r) => {
              response = r;
              done();
            });
          });

          it('returns 403', () => {
            expect(response.statusCode).to.eq(403);
          });
        });
      });
    });

    describe('when no user is found', () => {
      let response;
      beforeEach((done) => {
        stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(null));
        request(app).patch('/2').send({ type: 'member' }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns 404', () => {
        expect(response.statusCode).to.eq(404);
      });

      it('returns json with error', () => {
        expect(response.body.error).to.eq(true);
        expect(response.body.data.message).to.be.a('string');
      });
    });

    describe('success', () => {
      let response;
      let currentUserRole;
      let userToChange;
      beforeEach((done) => {
        currentUserRole = {
          user_id: user.id,
          team_id: team.id,
          type: 'member'
        };
        userToChange = {
          id: 2,
        };
        stub(RoleMock, 'findOne').callsFake(() => Promise.resolve({
          update: () => Promise.resolve(),
          user_id: userToChange.id,
          team_id: team.id,
          type: 'guest'
        }));
        stub(UserMock, 'findOne').callsFake(() => Promise.resolve(userToChange));
        app = makeApp({
          '../../helpers/hasRole': hasRole,
          '../../helpers/getRole': mockEsmodule({
            default: spy(() => currentUserRole)
          })
        });

        request(app).patch('/2').send({ type: 'member' }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns 200', () => {
        expect(response.statusCode).to.eq(200);
      });

      it('returns json with user', () => {
        expect(response.body.error).to.be.false;
        expect(response.body.data).to.deep.eq(userToChange);
      });
    });

    describe('failure', () => {
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../../helpers/hasRole': hasRole,
          '../../models': mockEsmodule({
            Role: {
              findOne: stub().throws('Oh No')
            }
          })
        });

        request(app).patch('/1').then((r) => {
          response = r;
          done();
        });
      });

      it('returns error', () => {
        expect(response.error.text).to.contain('Oh No');
      });
    });
  });

  describe('DELETE /:id', () => {
    describe('before query', () => {
      beforeEach(() =>
        request(app).delete('/1')
      );

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role of member or greater', () => {
        expect(checkTeamRoleSpy.calledWith('member')).to.be.true;
      });
    });

    describe('success', () => {
      let response;
      let roleToDestroy;
      let currentUserRole;
      let userToDelete;
      beforeEach((done) => {
        currentUserRole = {
          user_id: user.id,
          team_id: team.id,
          type: 'member'
        };
        userToDelete = {
          id: 2,
        };
        roleToDestroy = {
          destroy: spy(() => Promise.resolve()),
          user_id: userToDelete.id,
          team_id: team.id,
          type: 'guest'
        };
        stub(RoleMock, 'findOne').callsFake(() => Promise.resolve(roleToDestroy));
        stub(UserMock, 'findOne').callsFake(() => Promise.resolve(userToDelete));
        app = makeApp({
          '../../helpers/getRole': mockEsmodule({
            default: spy(() => currentUserRole)
          })
        });

        request(app).delete(`/${userToDelete.id}`).then(r => {
          response = r;
          done();
        });
      });

      it('deletes role', () => {
        expect(roleToDestroy.destroy.callCount).to.eq(1);
      });

      it('returns 204', () => {
        expect(response.statusCode).to.eq(204);
      });
    });
  });
});
