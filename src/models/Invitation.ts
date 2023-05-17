import { sequelize, DataTypes } from "./db";

const Invitation = sequelize.define(
  "invitation",
  {
    email: {
      type: DataTypes.CITEXT,
      allowNull: false,
      unique: true,
    },
    confirmedAt: {
      type: DataTypes.DATE,
    },
    confirmationToken: {
      type: DataTypes.STRING,
      unique: true,
    },
    confirmationSentAt: {
      type: DataTypes.DATE,
    },
  },
  {}
);

export default Invitation;
