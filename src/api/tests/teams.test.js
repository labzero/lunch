/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import { spy, stub } from 'sinon';
import bodyParser from 'body-parser';
import request from 'supertest';
import express from 'express';
import proxyquire from 'proxyquire';
import SequelizeMock from 'sequelize-mock';
import expressWs from 'express-ws';
import mockEsmodule from '../../../test/mockEsmodule';

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe('api/main/teams', () => {
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
        id: 231,
        roles: []
      };
      next();
    });

    makeApp = deps => {
      const teamsApi = proxyquireStrict('../main/teams', {
        '../../models': mockEsmodule({
          Team: TeamMock,
          Role: RoleMock
        }),
        '../helpers/loggedIn': mockEsmodule({
          default: loggedInSpy
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
        request(app).post('/').send({ name: 'Something', slug: 'something' })
      );

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });
    });

    describe('exceeds team limit', () => {
      let createSpy;
      let response;
      beforeEach((done) => {
        createSpy = spy(TeamMock, 'create');
        loggedInSpy = spy((req, res, next) => {
          req.user = { // eslint-disable-line no-param-reassign
            id: 231,
            roles: [{}, {}, {}, {}, {}]
          };
          next();
        });
        app = makeApp({
          '../../constants': mockEsmodule({
            TEAM_LIMIT: 5
          })
        });
        request(app).post('/').send({ name: 'Something', slug: 'something' }).then(r => {
          response = r;
          done();
        });
      });

      it('does not create team', () => {
        expect(createSpy.callCount).to.eq(0);
      });

      it('returns 403', () => {
        expect(response.statusCode).to.eq(403);
      });

      it('returns json with error message', () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a('string');
      });
    });

    describe('reserved slug check', () => {
      let createSpy;
      let response;
      beforeEach((done) => {
        createSpy = spy(TeamMock, 'create');
        request(app).post('/').send({ name: 'World Wide What', slug: 'www' }).then(r => {
          response = r;
          done();
        });
      });

      it('does not create team', () => {
        expect(createSpy.callCount).to.eq(0);
      });

      it('returns 409', () => {
        expect(response.statusCode).to.eq(409);
      });

      it('returns json with error message', () => {
        expect(response.body.error).to.be.true;
        expect(response.body.data.message).to.be.a('string');
      });
    });

    describe('invalid slug', () => {
      let createSpy;
      let response;
      beforeEach(() => {
        createSpy = spy(TeamMock, 'create');
      });

      describe('with only numbers', () => {
        beforeEach((done) => {
          request(app).post('/').send({ name: 'Numbers', slug: '33' }).then(r => {
            response = r;
            done();
          });
        });

        it('does not create team', () => {
          expect(createSpy.callCount).to.eq(0);
        });

        it('returns 422', () => {
          expect(response.statusCode).to.eq(422);
        });

        it('returns json with error message', () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a('string');
        });
      });

      describe('with dashes at beginning', () => {
        beforeEach((done) => {
          request(app).post('/').send({ name: 'Beginning Dash', slug: '-abc' }).then(r => {
            response = r;
            done();
          });
        });

        it('does not create team', () => {
          expect(createSpy.callCount).to.eq(0);
        });

        it('returns 422', () => {
          expect(response.statusCode).to.eq(422);
        });

        it('returns json with error message', () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a('string');
        });
      });

      describe('with dashes at end', () => {
        beforeEach((done) => {
          request(app).post('/').send({ name: 'Ending Dash', slug: 'abc-' }).then(r => {
            response = r;
            done();
          });
        });

        it('does not create team', () => {
          expect(createSpy.callCount).to.eq(0);
        });

        it('returns 422', () => {
          expect(response.statusCode).to.eq(422);
        });

        it('returns json with error message', () => {
          expect(response.body.error).to.be.true;
          expect(response.body.data.message).to.be.a('string');
        });
      });
    });

    describe('queries', () => {
      let createSpy;
      beforeEach(() => {
        createSpy = spy(TeamMock, 'create');
        return request(app).post('/').send({ address: '77 Battery', lat: 123, lng: 321, name: 'Lab Zero', slug: 'labzero' });
      });

      it('creates new team', () => {
        expect(createSpy.calledWith({
          address: '77 Battery',
          lat: 123,
          lng: 321,
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
        request(app).post('/').send({ name: 'Lab Zero', slug: '333-labzero-333' }).then(r => {
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
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../../models': mockEsmodule({
            Team: {
              create: stub().throws(),
              destroy: TeamMock.destroy,
              scope: TeamMock.scope
            }
          }),
        });
        request(app).post('/').send({ name: 'blah', slug: 'blah' }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns error', () => {
        expect(response.error.text).to.exist;
      });
    });
  });

  describe('DELETE /:id', () => {
    let checkTeamRoleSpy;
    beforeEach(() => {
      checkTeamRoleSpy = spy(() => (req, res, next) => next());

      app = makeApp({
        '../helpers/checkTeamRole': checkTeamRoleSpy
      });
    });

    describe('before deletion', () => {
      let findOneSpy;
      beforeEach(() => {
        findOneSpy = spy(TeamMock, 'findOne');

        return request(app).delete('/1');
      });

      it('finds team', () => {
        expect(findOneSpy.calledWith({ where: { id: 1 } })).to.be.true;
      });

      it('checks for owner role', () => {
        expect(checkTeamRoleSpy.calledWith('owner')).to.be.true;
      });
    });

    describe('query', () => {
      let destroySpy;
      beforeEach(() => {
        destroySpy = spy();
        stub(TeamMock, 'findOne').callsFake(() => Promise.resolve({
          destroy: destroySpy
        }));

        return request(app).delete('/1');
      });

      it('deletes team', () => {
        expect(destroySpy.callCount).to.eq(1);
      });
    });

    describe('success', () => {
      let response;
      beforeEach((done) => {
        request(app).delete('/1').then(r => {
          response = r;
          done();
        });
      });

      it('returns 204', () => {
        expect(response.statusCode).to.eq(204);
      });
    });

    describe('failure', () => {
      let response;
      beforeEach((done) => {
        stub(TeamMock, 'findOne').callsFake(() => Promise.resolve({
          destroy: stub().throws('Oh No')
        }));
        app = makeApp({
          '../helpers/checkTeamRole': checkTeamRoleSpy,
        });
        request(app).delete('/1').then((r) => {
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
