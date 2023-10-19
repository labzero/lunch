import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.addColumn("teams", "slug", {
    type: DataTypes.STRING(63),
    unique: true,
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("teams", "slug");
