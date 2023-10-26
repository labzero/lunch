import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.changeColumn("users", "google_id", {
    type: DataTypes.STRING,
  });

export const down = ({ context: queryInterface }) => {
  const User = queryInterface.sequelize.define(
    "user",
    {
      google_id: DataTypes.STRING,
    },
    {
      underscored: true,
    }
  );

  return User.destroy({ where: { google_id: null } }).then(() =>
    queryInterface.changeColumn("users", "google_id", {
      type: DataTypes.STRING,
      allowNull: false,
    })
  );
};
