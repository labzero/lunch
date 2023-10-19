import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.addColumn("users", "encrypted_password", {
      type: DataTypes.STRING,
    }),
    queryInterface.addColumn("users", "reset_password_token", {
      type: DataTypes.STRING,
      unique: true,
    }),
    queryInterface.addColumn("users", "reset_password_sent_at", {
      type: DataTypes.DATE,
    }),
    queryInterface.addColumn("users", "confirmation_token", {
      type: DataTypes.STRING,
      unique: true,
    }),
    queryInterface.addColumn("users", "confirmed_at", {
      type: DataTypes.DATE,
    }),
    queryInterface.addColumn("users", "confirmation_sent_at", {
      type: DataTypes.DATE,
    }),
  ]);

exports.down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("users", "encrypted_password"),
    queryInterface.removeColumn("users", "reset_password_token"),
    queryInterface.removeColumn("users", "reset_password_sent_at"),
    queryInterface.removeColumn("users", "confirmation_token"),
    queryInterface.removeColumn("users", "confirmed_at"),
    queryInterface.removeColumn("users", "confirmation_sent_at"),
  ]);
