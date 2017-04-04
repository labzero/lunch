import { hostname } from '../config';

export default ({ name, email, ...others }) => ({
  from: `"Lunch" <noreply@${hostname}>`,
  to: `"${name}" <${email}>`,
  ...others
});
