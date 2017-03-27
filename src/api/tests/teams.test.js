/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import { match, spy, stub } from 'sinon';
import bodyParser from 'body-parser';
import request from 'supertest';
import express, { Router } from 'express';
import proxyquire from 'proxyquire';
import SequelizeMock from 'sequelize-mock';
import expressWs from 'express-ws';
import mockEsmodule from '../../../test/mockEsmodule';

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe('api/teams', () => {
  let app;
  let RoleMock;
  let TeamMock;
  let loggedInSpy;
  let makeApp;

  beforeEach(() => {
    TeamMock = dbMock.define('team', {});
    RoleMock = dbMock.define('role', {});

    loggedInSpy = spy((req, res, next) => {
      req.user = { // eslint-disable-line no-param-reassign
        id: 231
      };
      next();
    });

    makeApp = deps => {
      const teamsApi = proxyquireStrict('../teams', {
        '../models': mockEsmodule({
          Team: TeamMock,
          Role: RoleMock
        }),
        './helpers/getTeamIfHasRole': mockEsmodule({
          default: () => null
        }),
        './helpers/loggedIn': mockEsmodule({
          default: loggedInSpy
        }),
        './decisions': mockEsmodule({
          default: () => new Router()
        }),
        './restaurants': mockEsmodule({
          default: () => new Router()
        }),
        './tags': mockEsmodule({
          default: () => new Router()
        }),
        './users': mockEsmodule({
          default: () => new Router()
        }),
        ...deps
      }).default;

      const server = express();
      server.use(bodyParser.json());
      expressWs(server);
      server.use('/', teamsApi());
      return server;
    };

    app = makeApp();
  });

  describe('POST /', () => {
    describe('before query', () => {
      beforeEach(() =>
        request(app).post('/')
      );

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });
    });

    describe('reserved username check', () => {
      let createSpy;
      let errorCatcherSpy;
      beforeEach(() => {
        createSpy = spy(TeamMock, 'create');
        errorCatcherSpy = spy((res) => {
          res.send();
        });
        app = makeApp({
          './helpers/errorCatcher': mockEsmodule({
            default: errorCatcherSpy
          })
        });
        return request(app).post('/').send({ name: 'World Wide What', slug: 'www' });
      });

      it('does not create team', () => {
        expect(createSpy.callCount).to.eq(0);
      });

      it('calls errorCatcher', () => {
        expect(errorCatcherSpy.calledWith(match.any, { message: match.string })).to.be.true;
      });
    });

    describe('queries', () => {
      let createSpy;
      beforeEach(() => {
        createSpy = spy(TeamMock, 'create');
        return request(app).post('/').send({ name: 'Lab Zero', slug: 'labzero' });
      });

      it('creates new team', () => {
        expect(createSpy.calledWith({
          name: 'Lab Zero',
          slug: 'labzero',
          roles: [{
            user_id: 231,
            type: 'owner'
          }]
        })).to.be.true;
      });
    });

    describe('success', () => {
      let response;
      beforeEach((done) => {
        request(app).post('/').send({ name: 'Lab Zero', slug: 'labzero' }).then(r => {
          response = r;
          done();
        });
      });

      it('returns 201', () => {
        expect(response.statusCode).to.eq(201);
      });

      it('returns json with team', () => {
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
          '../models': mockEsmodule({
            Team: {
              create: stub().throws(),
              destroy: TeamMock.destroy,
              scope: TeamMock.scope
            }
          }),
          './helpers/errorCatcher': mockEsmodule({
            default: errorCatcherSpy
          })
        });
        return request(app).post('/');
      });

      it('calls errorCatcher', () => {
        expect(errorCatcherSpy.calledWith(match.any, { message: match.string })).to.be.true;
      });
    });
  });
});
