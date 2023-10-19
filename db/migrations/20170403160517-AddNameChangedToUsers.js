import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.addColumn("users", "name_changed", {
    defaultValue: false,
    type: DataTypes.BOOLEAN,
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("users", "name_changed");
