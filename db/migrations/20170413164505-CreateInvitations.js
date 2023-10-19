import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.createTable("invitations", {
    id: {
      allowNull: false,
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    created_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    updated_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    confirmed_at: {
      type: DataTypes.DATE,
    },
    confirmation_token: {
      type: DataTypes.STRING,
      unique: true,
    },
    confirmation_sent_at: {
      type: DataTypes.DATE,
    },
  });

exports.down = ({ context: queryInterface }) =>
  queryInterface.dropTable("invitations");
