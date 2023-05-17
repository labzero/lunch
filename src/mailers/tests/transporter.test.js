/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from "chai";
import { spy } from "sinon";
import proxyquire from "proxyquire";
import { mail } from "sendgrid";
import mockEsmodule from "../../../test/mockEsmodule";

const proxyquireStrict = proxyquire.noCallThru();

describe("mailers/transporter", () => {
  let emptyRequestSpy;
  let transporter;
  beforeEach(() => {
    emptyRequestSpy = spy();
    transporter = proxyquireStrict("../transporter", {
      sendgrid: mockEsmodule({
        default: () => ({
          emptyRequest: emptyRequestSpy,
          API: () => undefined,
        }),
        mail,
      }),
      "../config": mockEsmodule({
        auth: {
          sendgrid: {
            secret: "12345",
          },
        },
        hostname: "lunch.pink",
      }),
    }).default;
  });

  describe("sendMail", () => {
    describe("when sending to an individual user", () => {
      beforeEach(() => {
        transporter.sendMail({
          name: "Jeffrey",
          email: "j@l.com",
          subject: "Hello",
          text: "Hi!",
        });
      });

      it("contains the to email in the tos value", () => {
        const body = emptyRequestSpy.lastCall.args[0].body;
        expect(body.subject).to.eq("Hello");
        expect(body.personalizations[0].to[0]).to.deep.eq({
          name: "Jeffrey",
          email: "j@l.com",
        });
      });
    });

    describe("when sending to a list of recipients", () => {
      beforeEach(() => {
        transporter.sendMail({
          recipients: [
            {
              name: "Jeffrey",
              email: "j@l.com",
            },
            {
              name: "Matt",
              email: "m@l.com",
            },
          ],
          subject: "Hello",
          text: "Hi!",
        });
      });

      it("makes Lunch the sender and sendee", () => {
        const body = emptyRequestSpy.lastCall.args[0].body;

        expect(body.from).to.deep.eq({
          name: "Lunch",
          email: "noreply@lunch.pink",
        });
        expect(body.personalizations[0].to[0]).to.deep.eq({
          name: "Lunch",
          email: "noreply@lunch.pink",
        });
      });

      it("contains the emails in the bccs value", () => {
        const body = emptyRequestSpy.lastCall.args[0].body;
        expect(body.personalizations[0].bcc).to.deep.contain.members([
          {
            name: "Jeffrey",
            email: "j@l.com",
          },
          {
            name: "Matt",
            email: "m@l.com",
          },
        ]);
      });
    });
  });
});
