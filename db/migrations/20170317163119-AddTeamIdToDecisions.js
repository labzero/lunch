exports.up = (queryInterface, Sequelize) => {
  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: Sequelize.STRING,
      slug: Sequelize.STRING(63),
    },
    {
      underscored: true,
    }
  );

  return Team.findOne().then((team) =>
    queryInterface.addColumn("decisions", "team_id", {
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
  queryInterface.removeColumn("decisions", "team_id");
