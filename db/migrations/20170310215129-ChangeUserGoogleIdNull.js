exports.up = (queryInterface, Sequelize) =>
  queryInterface.changeColumn("users", "google_id", {
    type: Sequelize.STRING,
  });

exports.down = (queryInterface, Sequelize) => {
  const User = queryInterface.sequelize.define(
    "user",
    {
      google_id: Sequelize.STRING,
    },
    {
      underscored: true,
    }
  );

  return User.destroy({ where: { google_id: null } }).then(() =>
    queryInterface.changeColumn("users", "google_id", {
      type: Sequelize.STRING,
      allowNull: false,
    })
  );
};
