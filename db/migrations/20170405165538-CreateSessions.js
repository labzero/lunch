import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.createTable("Sessions", {
    sid: {
      type: DataTypes.STRING(32),
      primaryKey: true,
    },
    expires: DataTypes.DATE,
    data: DataTypes.TEXT,
    createdAt: DataTypes.DATE,
    updatedAt: DataTypes.DATE,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.dropTable("Sessions", {});
