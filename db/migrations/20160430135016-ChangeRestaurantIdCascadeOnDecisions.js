exports.up = (queryInterface, Sequelize) =>
  queryInterface.sequelize.query(
    'ALTER TABLE decisions DROP CONSTRAINT IF EXISTS decisions_restaurant_id_fkey'
  ).then(() =>
    queryInterface.sequelize.query(
      'ALTER TABLE decisions DROP CONSTRAINT IF EXISTS restaurant_id_foreign_idx'
    ).then(() =>
      queryInterface.changeColumn('decisions', 'restaurant_id', {
        type: Sequelize.INTEGER,
        references: {
          model: 'restaurants',
          key: 'id'
        },
        allowNull: false,
        onDelete: 'cascade'
      })
    )
  );

exports.down = (queryInterface, Sequelize) =>
  queryInterface.sequelize.query(
    'ALTER TABLE decisions DROP CONSTRAINT IF EXISTS restaurant_id_foreign_idx'
  ).then(() =>
    queryInterface.changeColumn('decisions', 'restaurant_id', {
      type: Sequelize.INTEGER,
      references: {
        model: 'restaurants',
        key: 'id'
      },
      allowNull: false
    })
  );
