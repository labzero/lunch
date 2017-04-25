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

describe('middlewares/invitation', () => {
  let app;
  let makeApp;
  let sendMailSpy;
  let InvitationMock;
  let RoleMock;
  let UserMock;
  let flashSpy;

  beforeEach(() => {
    InvitationMock = dbMock.define('invitation', {});
    RoleMock = dbMock.define('role', {});
    UserMock = dbMock.define('user', {});
    sendMailSpy = spy();
    flashSpy = spy();
    makeApp = (deps) => {
      const invitationMiddleware = proxyquireStrict('../invitation', {
        '../models': mockEsmodule({
          Invitation: InvitationMock,
          Role: RoleMock,
          User: UserMock
        }),
        '../mailers/transporter': mockEsmodule({
          default: {
            sendMail: sendMailSpy
          }
        }),
        ...deps
      }).default;

      const server = express();
      server.use(bodyParser.json());
      server.use((req, res, next) => {
        req.flash = flashSpy; // eslint-disable-line no-param-reassign
        req.session = { // eslint-disable-line no-param-reassign
          save: cb => cb()
        };
        next();
      });
      server.use('/', invitationMiddleware());
      return server;
    };

    app = makeApp();
  });

  describe('POST /', () => {
    let updateSpy;
    beforeEach(() => {
      updateSpy = spy();
    });

    describe('when invitation has already been confirmed', () => {
      let response;
      beforeEach((done) => {
        stub(InvitationMock, 'findOne').callsFake(() => Promise.resolve({
          get: () => true
        }));

        request(app).post('/').send({ email: 'jeffrey@labzero.com' }).then((r) => {
          response = r;
          done();
        });
      });

      it('sets flash error', () => {
        expect(flashSpy.calledWith('error', match.string)).to.be.true;
      });

      it('returns 302', () => {
        expect(response.statusCode).to.eq(302);
      });

      it('redirects to password reset request page', () => {
        expect(response.headers.location).to.eq('/invitation/new');
      });
    });

    describe('when confirmation was recently sent', () => {
      let response;
      beforeEach((done) => {
        stub(InvitationMock, 'findOne').callsFake(() => Promise.resolve({
          get: stub()
                 .onFirstCall()
                 .returns(false)
                 .onSecondCall()
                 .returns(new Date())
        }));

        request(app).post('/').send({ email: 'jeffrey@labzero.com' }).then((r) => {
          response = r;
          done();
        });
      });

      it('sets flash error', () => {
        expect(flashSpy.calledWith('error', match.string)).to.be.true;
      });

      it('returns 302', () => {
        expect(response.statusCode).to.eq(302);
      });

      it('redirects to password reset request page', () => {
        expect(response.headers.location).to.eq('/invitation/new');
      });
    });

    describe('when confirmation was sent over a day ago', () => {
      beforeEach(() => {
        stub(InvitationMock, 'findOne').callsFake(() => Promise.resolve({
          get: stub()
                 .onFirstCall()
                 .returns(false)
                 .onSecondCall()
                 .returns(new Date() - (60 * 60 * 1000 * 24)),
          update: updateSpy
        }));

        return request(app).post('/').send({ email: 'jeffrey@labzero.com' });
      });

      it('sends confirmation', () => {
        expect(sendMailSpy.calledWith(match({ email: 'jeffrey@labzero.com' }))).to.be.true;
      });

      it('updates confirmation_sent_at', () => {
        expect(updateSpy.calledWith({ confirmation_sent_at: match.date })).to.be.true;
      });

      it('sets flash success', () => {
        expect(flashSpy.calledWith('success', match.string)).to.be.true;
      });
    });
  });
});
