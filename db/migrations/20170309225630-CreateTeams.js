import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) => {
  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: DataTypes.STRING,
    },
    {
      underscored: true,
    }
  );

  return queryInterface
    .createTable("teams", {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: DataTypes.INTEGER,
      },
      name: {
        allowNull: false,
        type: DataTypes.STRING,
      },
      created_at: {
        allowNull: false,
        type: DataTypes.DATE,
      },
      updated_at: {
        allowNull: false,
        type: DataTypes.DATE,
      },
    })
    .then(() =>
      Team.create({
        name: "Lab Zero",
      })
    );
};

exports.down = ({ context: queryInterface }) =>
  queryInterface.dropTable("teams");
