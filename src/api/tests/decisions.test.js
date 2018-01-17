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

describe('api/team/decisions', () => {
  let app;
  let checkTeamRoleSpy;
  let DecisionMock;
  let loggedInSpy;
  let makeApp;
  let broadcastSpy;

  beforeEach(() => {
    DecisionMock = dbMock.define('decision', {});

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
      const decisionsApi = proxyquireStrict('../team/decisions', {
        '../../models': mockEsmodule({
          Decision: DecisionMock,
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
      server.use('/', decisionsApi());
      return server;
    };

    app = makeApp();
  });

  describe('GET /fromToday', () => {
    describe('before query', () => {
      beforeEach(() =>
        request(app).get('/fromToday'));

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role', () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe('success', () => {
      let response;
      beforeEach((done) => {
        request(app).get('/fromToday').then(r => {
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
        stub(DecisionMock, 'scope').throws('Oh No');

        request(app).get('/fromToday').then((r) => {
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
    describe('before query', () => {
      beforeEach(() =>
        request(app).post('/'));

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });

      it('checks for team role', () => {
        expect(checkTeamRoleSpy.called).to.be.true;
      });
    });

    describe('queries', () => {
      let destroySpy;
      let createSpy;
      beforeEach(() => {
        destroySpy = spy(DecisionMock, 'destroy');
        createSpy = spy(DecisionMock, 'create');
        return request(app).post('/').send({ restaurant_id: 1 });
      });

      it('deletes any prior decisions', () => {
        expect(destroySpy.calledWith({
          where: { team_id: 77 }
        })).to.be.true;
      });

      it('creates new decision', () => {
        expect(createSpy.calledWith({
          restaurant_id: 1,
          team_id: 77
        })).to.be.true;
      });
    });

    describe('success', () => {
      let decisionPostedSpy;
      let response;
      beforeEach((done) => {
        decisionPostedSpy = spy();
        app = makeApp({
          '../../actions/decisions': mockEsmodule({
            decisionPosted: decisionPostedSpy
          })
        });

        request(app).post('/').send({ restaurant_id: 1 }).then(r => {
          response = r;
          done();
        });
      });

      it('broadcasts decisionPosted', () => {
        expect(broadcastSpy.called).to.be.true;
        expect(decisionPostedSpy.calledWith(match.any, match.array, 231)).to.be.true;
      });

      it('returns 201', () => {
        expect(response.statusCode).to.eq(201);
      });

      it('returns json with decision', () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).not.to.be.null;
      });
    });

    describe('failure', () => {
      describe('when destroying', () => {
        let response;
        beforeEach((done) => {
          stub(DecisionMock, 'scope').throws('Oh No');

          request(app).post('/').then((r) => {
            response = r;
            done();
          });
        });

        it('returns error', () => {
          expect(response.error.text).to.contain('Oh No');
        });
      });

      describe('when creating', () => {
        let response;
        beforeEach((done) => {
          app = makeApp({
            '../../models': mockEsmodule({
              Decision: {
                create: stub().throws(),
                destroy: DecisionMock.destroy,
                scope: DecisionMock.scope
              }
            }),
          });

          request(app).post('/').then((r) => {
            response = r;
            done();
          });
        });

        it('returns error', () => {
          expect(response.error.text).to.exist;
        });
      });
    });
  });

  describe('DELETE /fromToday', () => {
    describe('before query', () => {
      beforeEach(() =>
        request(app).delete('/fromToday'));

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
          '../../actions/decisions': mockEsmodule({
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
      let response;
      beforeEach((done) => {
        stub(DecisionMock, 'scope').throws('Oh No');

        request(app).delete('/fromToday').then((r) => {
          response = r;
          done();
        });
      });

      it('returns error', () => {
        expect(response.error.text).to.contain('Oh No');
      });
    });
  });
});
