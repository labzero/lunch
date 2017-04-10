import sendgrid, { mail as helper } from 'sendgrid';
import { auth, hostname } from '../config';

const sg = sendgrid(auth.sendgrid.secret);

const transporter = {
  sendMail: (options) => {
    const fromEmail = helper.Email(`noreply@${hostname}`, 'Lunch');
    const toEmail = helper.Email(options.email, options.name);
    const content = helper.Content('text/plain', options.text);
    const mail = helper.Mail(fromEmail, options.subject, toEmail, content);

    const request = sg.emptyRequest({
      method: 'POST',
      path: '/v3/mail/send',
      body: mail.toJSON()
    });

    return sg.API(request);
  }
};

export default transporter;
