import { DataTypes } from "sequelize";

export const up = async ({ context: queryInterface }) => {
  await queryInterface.sequelize.query(
    "CREATE EXTENSION IF NOT EXISTS citext;"
  );
  await queryInterface.changeColumn("users", "email", {
    type: DataTypes.CITEXT,
  });
};

export const down = async ({ context: queryInterface }) => {
  await queryInterface.changeColumn("users", "email", {
    type: DataTypes.STRING,
  });
  await queryInterface.sequelize.query("DROP EXTENSION citext;");
};
