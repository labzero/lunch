import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.addColumn("teams", "lat", {
      type: DataTypes.DOUBLE,
    }),
    queryInterface.addColumn("teams", "lng", {
      type: DataTypes.DOUBLE,
    }),
    queryInterface.addColumn("teams", "address", {
      type: DataTypes.STRING,
    }),
  ]);

exports.down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("teams", "lat"),
    queryInterface.removeColumn("teams", "lng"),
    queryInterface.removeColumn("teams", "address"),
  ]);
