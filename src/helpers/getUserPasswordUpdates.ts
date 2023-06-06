import bcrypt from "bcrypt";
import { User } from "../interfaces";

export default async (user: User, password: string) => {
  const encryptedPassword = await bcrypt.hash(password, 10);
  const updates: {
    encryptedPassword: string;
    resetPasswordToken: null;
    resetPasswordSentAt: null;
    confirmedAt?: Date;
  } = {
    encryptedPassword,
    resetPasswordToken: null,
    resetPasswordSentAt: null,
  };
  if (!user.get("confirmedAt")) {
    updates.confirmedAt = new Date();
  }
  return updates;
};
