import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.addColumn("restaurants", "place_id", {
      type: DataTypes.STRING,
      unique: true,
    }),
    queryInterface.addColumn("restaurants", "lat", {
      type: DataTypes.FLOAT,
    }),
    queryInterface.addColumn("restaurants", "lng", {
      type: DataTypes.FLOAT,
    }),
  ]);

export const down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.removeColumn("restaurants", "place_id"),
    queryInterface.removeColumn("restaurants", "lat"),
    queryInterface.removeColumn("restaurants", "lng"),
  ]);
