import sendgrid, { mail as helper } from "sendgrid";
import { auth, hostname } from "../config";

const sg = sendgrid(auth.sendgrid.secret);

const transporter = {
  sendMail: (options) => {
    const mail = helper.Mail();

    mail.setSubject(options.subject);

    const fromEmail = helper.Email(`noreply@${hostname}`, "Lunch");
    mail.setFrom(fromEmail);

    const personalization = new helper.Personalization();
    if (options.email) {
      const toEmail = helper.Email(options.email, options.name);
      personalization.addTo(toEmail);
    } else if (options.recipients) {
      options.recipients.forEach((r, i) => {
        // Sendgrid's recipient limit is 1000 (to + bcc)
        if (i < 999) {
          const email = new helper.Email(r.email, r.name);
          personalization.addBcc(email);
        }
      });
      personalization.addTo(fromEmail);
    }
    mail.addPersonalization(personalization);

    const content = helper.Content("text/plain", options.text);
    mail.addContent(content);

    const request = sg.emptyRequest({
      method: "POST",
      path: "/v3/mail/send",
      body: mail.toJSON(),
    });

    return sg.API(request);
  },
};

export default transporter;
