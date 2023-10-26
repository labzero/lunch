import { DataTypes } from "sequelize";

export const up = async ({ context: queryInterface }) => {
  await queryInterface.changeColumn("invitations", "email", {
    type: DataTypes.CITEXT,
  });
};

export const down = async ({ context: queryInterface }) => {
  await queryInterface.changeColumn("invitations", "email", {
    type: DataTypes.STRING,
  });
};
