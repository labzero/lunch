exports.up = (queryInterface, Sequelize) =>
  queryInterface.changeColumn("users", "email", {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true,
  });

exports.down = (queryInterface, Sequelize) =>
  queryInterface
    .changeColumn("users", "email", {
      type: Sequelize.STRING,
      allowNull: true,
      unique: false,
    })
    .then(() =>
      queryInterface.sequelize.query(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS email_unique_idx;"
      )
    );
