exports.up = (queryInterface, Sequelize) => {
  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: Sequelize.STRING,
    },
    {
      underscored: true,
    }
  );

  return Team.findOne().then((team) =>
    queryInterface.addColumn("restaurants", "team_id", {
      type: Sequelize.INTEGER,
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

exports.down = (queryInterface) =>
  queryInterface.removeColumn("restaurants", "team_id");
