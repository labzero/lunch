import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.changeColumn("users", "email", {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  });

export const down = ({ context: queryInterface }) =>
  queryInterface
    .changeColumn("users", "email", {
      type: DataTypes.STRING,
      allowNull: true,
      unique: false,
    })
    .then(() =>
      queryInterface.sequelize.query(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS email_unique_idx;"
      )
    );
