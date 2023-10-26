import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.addColumn("teams", "default_zoom", {
    type: DataTypes.INTEGER,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("teams", "default_zoom");
