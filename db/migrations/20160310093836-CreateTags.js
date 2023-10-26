import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.createTable("tags", {
    id: {
      allowNull: false,
      autoIncrement: true,
      primaryKey: true,
      type: DataTypes.INTEGER,
    },
    name: {
      type: DataTypes.STRING,
      unique: true,
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
  queryInterface.dropTable("tags", {});
