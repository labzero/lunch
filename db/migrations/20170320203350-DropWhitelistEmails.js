import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.dropTable("whitelist_emails", {});

export const down = ({ context: queryInterface }) =>
  queryInterface.createTable("whitelist_emails", {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    created_at: {
      allowNull: false,
      type: DataTypes.DATE,
    },
    updated_at: {
      allowNull: false,
      type: DataTypes.DATE,
    },
  });
