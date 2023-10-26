import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) => {
  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: DataTypes.STRING,
    },
    {
      underscored: true,
    }
  );

  return Team.findOne().then((team) =>
    queryInterface.addColumn("restaurants", "team_id", {
      type: DataTypes.INTEGER,
      references: {
        model: "teams",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
      defaultValue: team.id,
    })
  );
};

export const down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("restaurants", "team_id");
