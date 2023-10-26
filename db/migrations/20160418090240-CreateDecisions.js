import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.createTable("decisions", {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    restaurant_id: {
      type: DataTypes.INTEGER,

      references: {
        model: "restaurants",
        key: "id",
      },
      allowNull: false,
    },
    created_at: {
      allowNull: false,
      type: DataTypes.DATE,
    },
    updated_at: {
      allowNull: false,
      type: DataTypes.DATE,
    },
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.dropTable("decisions", {});
