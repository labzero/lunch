import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.createTable("restaurants", {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.dropTable("restaurants", {});
