import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
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

export const down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("teams", "lat"),
    queryInterface.removeColumn("teams", "lng"),
    queryInterface.removeColumn("teams", "address"),
  ]);
