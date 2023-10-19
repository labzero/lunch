import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
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

exports.down = ({ context: queryInterface }) =>
  queryInterface.dropTable("Sessions", {});
