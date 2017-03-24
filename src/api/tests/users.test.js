/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle */

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

describe('api/users', () => {
  let app;
  let checkTeamRoleSpy;
  let RoleMock;
  let UserMock;
  let loggedInSpy;
  let makeApp;
  let broadcastSpy;

  beforeEach(() => {
    UserMock = dbMock.define('user', {});
    RoleMock = dbMock.define('role', {});

    checkTeamRoleSpy = spy(() => (req, res, next) => {
      req.team = { // eslint-disable-line no-param-reassign
        id: 77,
        stub: 'Lab Zero'
      };
      next();
    });

    loggedInSpy = spy((req, res, next) => {
      req.user = { // eslint-disable-line no-param-reassign
        id: 231
      };
      next();
    });

    broadcastSpy = spy();

    makeApp = deps => {
      const usersApi = proxyquireStrict('../users', {
        '../models': mockEsmodule({
          Role: RoleMock,
          User: UserMock,
        }),
        './helpers/loggedIn': mockEsmodule({
          default: loggedInSpy
        }),
        './helpers/checkTeamRole': mockEsmodule({
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
      server.use('/', usersApi);
      return server;
    };

    app = makeApp();
  });

  describe('GET /', () => {
    beforeEach(() => {
      app = makeApp({
        '../helpers/hasRole': mockEsmodule({
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
            '../helpers/hasRole': mockEsmodule({
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
      let errorCatcherSpy;
      beforeEach(() => {
        errorCatcherSpy = spy((res) => {
          res.send();
        });
        app = makeApp({
          '../helpers/hasRole': mockEsmodule({
            default: () => true
          }),
          '../models': mockEsmodule({
            User: {
              scope: stub().throws('Oh No')
            }
          }),
          './helpers/errorCatcher': mockEsmodule({
            default: errorCatcherSpy
          })
        });

        return request(app).get('/');
      });

      it('calls errorCatcher', () => {
        expect(errorCatcherSpy.calledWith(match.any, match({ name: 'Oh No' }))).to.be.true;
      });
    });
  });

  describe('POST /', () => {
    describe('before query', () => {
      beforeEach(() =>
        request(app).post('/')
      );

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
          '../helpers/hasRole': mockEsmodule({
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
          '../helpers/hasRole': mockEsmodule({
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

    describe('when user exists', () => {
      beforeEach(() => {
        stub(UserMock, 'findOne').callsFake(() => Promise.resolve({
          id: 2
        }));
      });

      describe('and is already on team', () => {
        let response;
        beforeEach((next) => {
          app = makeApp({
            '../helpers/hasRole': mockEsmodule({
              default: () => true
            })
          });
          request(app).post('/').send({ email: 'foo@bar.com', type: 'member' }).then(r => {
            response = r;
            next();
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

      describe('but is not on team', () => {
        let createSpy;
        beforeEach(() => {
          app = makeApp({
            '../helpers/hasRole': mockEsmodule({
              default: stub()
                .onFirstCall()
                .returns(true)
                .onSecondCall()
                .returns(false)
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
      });
    });

    describe('when user does not exist', () => {
      let createStub;
      let findOneStub;
      beforeEach(() => {
        app = makeApp({
          '../helpers/hasRole': mockEsmodule({
            default: () => true
          })
        });
        findOneStub = stub(UserMock, 'findOne')
          .callsFake(() => Promise.resolve(null));
        createStub = stub(UserMock, 'create')
          .callsFake(() => Promise.resolve({ id: 2 }));
        return request(app).post('/').send({ email: 'foo@bar.com', name: 'Jeffrey', type: 'member' });
      });

      it('creates user', () => {
        expect(createStub.calledWith({
          email: 'foo@bar.com',
          name: 'Jeffrey',
          roles: [{
            team_id: 77,
            type: 'member'
          }]
        })).to.be.true;
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
      let user;
      let response;
      beforeEach((done) => {
        user = { id: 2 };
        app = makeApp({
          '../helpers/hasRole': mockEsmodule({
            default: () => true
          })
        });
        stub(UserMock, 'findOne')
          .onFirstCall()
          .callsFake(() => Promise.resolve(null))
          .onSecondCall()
          .callsFake(() => Promise.resolve(user));
        stub(UserMock, 'create')
          .callsFake(() => Promise.resolve(user));
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
        expect(response.body.data).to.deep.eq(user);
      });
    });

    describe('failure', () => {
      let errorCatcherSpy;

      beforeEach(() => {
        errorCatcherSpy = spy((res) => {
          res.send();
        });
        app = makeApp({
          '../helpers/hasRole': mockEsmodule({
            default: () => true
          }),
          './helpers/errorCatcher': mockEsmodule({
            default: errorCatcherSpy
          })
        });
        stub(UserMock, 'findOne').throws('Oh No');

        return request(app).post('/');
      });

      it('calls errorCatcher', () => {
        expect(errorCatcherSpy.calledWith(match.any, match({ name: 'Oh No' }))).to.be.true;
      });
    });
  });
/*
  describe('DELETE /fromToday', () => {
    describe('before query', () => {
      beforeEach(() =>
        request(app).delete('/fromToday')
      );

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role', () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe('query', () => {
      let destroySpy;
      beforeEach(() => {
        destroySpy = spy(DecisionMock, 'destroy');
        return request(app).delete('/fromToday').send({ restaurant_id: 1 });
      });

      it('deletes decision', () => {
        expect(destroySpy.calledWith({
          where: { team_id: 77 }
        })).to.be.true;
      });
    });

    describe('success', () => {
      let decisionDeletedSpy;
      let response;
      beforeEach((done) => {
        decisionDeletedSpy = spy();
        app = makeApp({
          '../actions/decisions': mockEsmodule({
            decisionDeleted: decisionDeletedSpy
          })
        });

        request(app).delete('/fromToday').send({ restaurant_id: 1 }).then(r => {
          response = r;
          done();
        });
      });

      it('broadcasts decisionDeleted', () => {
        expect(broadcastSpy.called).to.be.true;
        expect(decisionDeletedSpy.calledWith(1, 231)).to.be.true;
      });

      it('returns 204', () => {
        expect(response.statusCode).to.eq(204);
      });
    });

    describe('failure', () => {
      let errorCatcherSpy;
      beforeEach(() => {
        errorCatcherSpy = spy((res) => {
          res.send();
        });

        app = makeApp({
          '../models': mockEsmodule({
            Decision: {
              scope: stub().throws('Oh No')
            }
          }),
          './helpers/errorCatcher': mockEsmodule({
            default: errorCatcherSpy
          })
        });

        return request(app).delete('/fromToday');
      });

      it('calls errorCatcher', () => {
        expect(errorCatcherSpy.calledWith(match.any, match({ name: 'Oh No' }))).to.be.true;
      });
    });
  });*/
});
