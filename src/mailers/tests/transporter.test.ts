/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from "chai";
import { SinonSpy, spy } from "sinon";
import proxyquire from "proxyquire";
import mockEsmodule from "../../../test/mockEsmodule";
import { User } from "../../interfaces";
import transporterOrig from "../transporter";

const proxyquireStrict = proxyquire.noCallThru();

describe("mailers/transporter", () => {
  let sendSpy: SinonSpy;
  let transporter: typeof transporterOrig;
  beforeEach(() => {
    sendSpy = spy();
    transporter = proxyquireStrict("../transporter", {
      "@sendgrid/mail": mockEsmodule({
        default: {
          send: sendSpy,
          setApiKey: () => undefined,
        },
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
        const body = sendSpy.lastCall.args[0];
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
          ] as User[],
          subject: "Hello",
          text: "Hi!",
        });
      });

      it("makes Lunch the sender and sendee", () => {
        const body = sendSpy.lastCall.args[0];

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
        const body = sendSpy.lastCall.args[0];
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
