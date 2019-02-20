import commonPassword from 'common-password';
import { PASSWORD_MIN_LENGTH } from '../constants';

export default (password) => {
  if (!password || password.length < PASSWORD_MIN_LENGTH) {
    return `Password must be at least ${PASSWORD_MIN_LENGTH} characters long.`;
  } if (commonPassword(password)) {
    return 'The password you provided is too common. Please try another one.';
  }
  return undefined;
};
