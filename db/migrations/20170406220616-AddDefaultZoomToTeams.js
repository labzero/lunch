import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.addColumn("teams", "default_zoom", {
    type: DataTypes.INTEGER,
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("teams", "default_zoom");
