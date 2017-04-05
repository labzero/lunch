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

describe('middlewares/password', () => {
  let app;
  let hashSpy;
  let makeApp;
  let sendMailSpy;
  let UserMock;
  let flashSpy;

  beforeEach(() => {
    UserMock = dbMock.define('user', {});
    UserMock.generateToken = () => Promise.resolve('12345');
    sendMailSpy = spy();
    hashSpy = spy(() => Promise.resolve('drowssap taerg a'));
    flashSpy = spy();
    makeApp = (deps) => {
      const passwordMiddleware = proxyquireStrict('../password', {
        bcrypt: mockEsmodule({
          default: {
            hash: hashSpy
          }
        }),
        '../models': mockEsmodule({
          User: UserMock,
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
      server.use('/', passwordMiddleware());
      return server;
    };

    app = makeApp();
  });

  describe('POST /', () => {
    let updateSpy;
    beforeEach(() => {
      updateSpy = spy();
    });

    describe('when user exists', () => {
      beforeEach(() => {
        stub(UserMock, 'findOne').callsFake(() => Promise.resolve({
          update: updateSpy
        }));

        return request(app).post('/').send({ email: 'jeffrey@labzero.com' });
      });

      it('updates user with new token', () => {
        expect(updateSpy.calledWith({
          reset_password_token: '12345',
          reset_password_sent_at: match.date
        })).to.be.true;
      });

      it('sends mail', () => {
        expect(sendMailSpy.callCount).to.eq(1);
      });
    });

    describe('when user does not exist', () => {
      beforeEach(() => {
        stub(UserMock, 'findOne').callsFake(() => null);

        return request(app).post('/').send({ email: 'jeffrey@labzero.com' });
      });

      it('does not update any user', () => {
        expect(updateSpy.callCount).to.eq(0);
      });

      it('does not send mail', () => {
        expect(sendMailSpy.callCount).to.eq(0);
      });
    });
  });

  describe('PUT /', () => {
    describe('when user does not exist', () => {
      let response;
      beforeEach((done) => {
        stub(UserMock, 'findOne').callsFake(() => null);

        request(app).put('/').send({
          password: 'a great password',
          reset_password_token: '12345'
        }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns 302', () => {
        expect(response.statusCode).to.eq(302);
      });

      it('redirects to password reset request page', () => {
        expect(response.headers.location).to.eq('/password/new');
      });
    });

    describe('when user does not have valid reset password token', () => {
      let response;
      beforeEach((done) => {
        stub(UserMock, 'findOne').callsFake(() => ({
          resetPasswordValid: () => false
        }));

        request(app).put('/').send({
          password: 'a great password',
          reset_password_token: '12345'
        }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns 302', () => {
        expect(response.statusCode).to.eq(302);
      });

      it('redirects to password reset request page', () => {
        expect(response.headers.location).to.eq('/password/new');
      });
    });

    describe('when user submits password that is too short', () => {
      let response;
      let updateSpy;
      beforeEach((done) => {
        updateSpy = spy(() => Promise.resolve());
        stub(UserMock, 'findOne').callsFake(() => ({
          get: () => false,
          update: updateSpy,
          resetPasswordValid: () => true
        }));

        request(app).put('/').send({
          password: 'short',
          reset_password_token: '12345'
        }).then((r) => {
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

      it('does not update password', () => {
        expect(updateSpy.callCount).to.eq(0);
      });
    });

    describe('when user submits password that is too common', () => {
      let response;
      let updateSpy;
      beforeEach((done) => {
        updateSpy = spy(() => Promise.resolve());
        stub(UserMock, 'findOne').callsFake(() => ({
          get: () => false,
          update: updateSpy,
          resetPasswordValid: () => true
        }));

        request(app).put('/').send({
          password: 'password',
          reset_password_token: '12345'
        }).then((r) => {
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

      it('does not update password', () => {
        expect(updateSpy.callCount).to.eq(0);
      });
    });

    describe('when user has valid reset token', () => {
      let updateSpy;
      beforeEach(() => {
        updateSpy = spy(() => Promise.resolve());
        stub(UserMock, 'findOne').callsFake(() => ({
          get: () => false,
          update: updateSpy,
          resetPasswordValid: () => true
        }));

        return request(app).put('/').send({
          password: 'a great password',
          reset_password_token: '12345'
        });
      });

      it('updates user', () => {
        expect(updateSpy.calledWith({
          encrypted_password: 'drowssap taerg a',
          reset_password_token: null,
          reset_password_sent_at: null,
          confirmed_at: match.date
        })).to.be.true;
      });
    });
  });

  describe('GET /edit', () => {
    describe('when user does not exist', () => {
      let response;
      beforeEach((done) => {
        stub(UserMock, 'findOne').callsFake(() => null);

        request(app).get('/edit').then((r) => {
          response = r;
          done();
        });
      });

      it('returns 302', () => {
        expect(response.statusCode).to.eq(302);
      });

      it('redirects to password reset request page', () => {
        expect(response.headers.location).to.eq('/password/new');
      });
    });

    describe('when user does not have valid reset password token', () => {
      let response;
      beforeEach((done) => {
        stub(UserMock, 'findOne').callsFake(() => ({
          resetPasswordValid: () => false
        }));

        request(app).get('/edit').then((r) => {
          response = r;
          done();
        });
      });

      it('returns 302', () => {
        expect(response.statusCode).to.eq(302);
      });

      it('redirects to password reset request page', () => {
        expect(response.headers.location).to.eq('/password/new');
      });
    });
  });
});
