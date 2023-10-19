import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
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

exports.down = ({ context: queryInterface }) =>
  queryInterface.dropTable("tags", {});
