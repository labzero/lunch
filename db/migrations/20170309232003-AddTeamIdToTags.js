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

  return Team.findOne().then((team) =>
    queryInterface.addColumn("tags", "team_id", {
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

exports.down = ({ context: queryInterface }) =>
  queryInterface.removeColumn("tags", "team_id");
