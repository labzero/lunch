import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.addColumn("teams", "slug", {
    type: DataTypes.STRING(63),
    unique: true,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("teams", "slug");
