import bcrypt from 'bcrypt';

export default async (user, password) => {
  const encryptedPassword = await bcrypt.hash(password, 10);
  const updates = {
    encrypted_password: encryptedPassword,
    reset_password_token: null,
    reset_password_sent_at: null
  };
  if (!user.get('confirmed_at')) {
    updates.confirmed_at = new Date();
  }
  return updates;
};
