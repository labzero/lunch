import bcrypt from "bcrypt";

export default async (user, password) => {
  const encryptedPassword = await bcrypt.hash(password, 10);
  const updates = {
    encryptedPassword,
    resetPasswordToken: null,
    resetPasswordSentAt: null,
  };
  if (!user.get("confirmedAt")) {
    updates.confirmedAt = new Date();
  }
  return updates;
};
