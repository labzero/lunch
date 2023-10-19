import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.addColumn("restaurants", "address", {
    type: DataTypes.STRING,
    allowNull: false,
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("restaurants", "address");
