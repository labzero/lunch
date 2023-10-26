import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface
    .addColumn("users", "superuser", {
      allowNull: false,
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    })
    .then(() => {
      const User = queryInterface.sequelize.define(
        "user",
        {
          google_id: DataTypes.STRING,
          name: DataTypes.STRING,
          email: DataTypes.STRING,
          superuser: DataTypes.BOOLEAN,
        },
        {
          underscored: true,
        }
      );

      return User.update(
        {
          superuser: true,
        },
        {
          where: {
            email: "jeffrey@labzero.com",
          },
        }
      );
    });

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("users", "superuser");
