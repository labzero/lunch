import sgMail from "@sendgrid/mail";
import { EmailData } from "@sendgrid/helpers/classes/email-address";
import { MailDataRequired } from "@sendgrid/helpers/classes/mail";
import { auth, hostname } from "../config";
import { User } from "../interfaces";

sgMail.setApiKey(auth.sendgrid.secret!);

const transporter = {
  sendMail: (options: {
    email?: string;
    name?: string;
    recipients?: User[];
    subject: string;
    text: string;
  }) => {
    const fromEmail = {
      email: `noreply@${hostname}`,
      name: "Lunch",
    };

    const mail: MailDataRequired = {
      content: [{ type: "text/plain", value: options.text }],
      from: fromEmail,
      personalizations: [
        {
          bcc: [],
          to: [],
        },
      ],
      subject: options.subject,
    };

    if (options.email) {
      (mail.personalizations![0].to as EmailData[]).push({
        email: options.email,
        name: options.name,
      });
    } else if (options.recipients) {
      options.recipients.forEach((r, i) => {
        // Sendgrid's recipient limit is 1000 (to + bcc)
        if (i < 999) {
          (mail.personalizations![0].bcc as EmailData[]).push({
            email: r.email,
            name: r.name,
          });
        }
      });
      (mail.personalizations![0].to as EmailData[]).push(fromEmail);
    }

    return sgMail.send(mail);
  },
};

export default transporter;
