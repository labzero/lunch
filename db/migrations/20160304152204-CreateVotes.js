import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.createTable("votes", {
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
      onDelete: "cascade",
    },
    user_id: {
      type: DataTypes.INTEGER,

      references: {
        model: "users",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
    },
  });

export const down = ({ context: queryInterface }) =>
  queryInterface.dropTable("votes", {});
