import nodemailer from 'nodemailer';
import { auth } from '../config';

const transporter = nodemailer.createTransport({
  service: auth.smtp.service,
  auth: {
    user: auth.smtp.user,
    pass: auth.smtp.pass
  }
});

export default transporter;
