exports.up = (queryInterface, Sequelize) =>
  queryInterface.createTable('roles', {
    id: {
      allowNull: false,
      autoIncrement: true,
      primaryKey: true,
      type: Sequelize.INTEGER
    },
    type: {
      allowNull: false,
      type: Sequelize.ENUM('admin', 'owner'),
    },
    team_id: {
      type: Sequelize.INTEGER,
      references: {
        model: 'teams',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    },
    user_id: {
      type: Sequelize.INTEGER,
      references: {
        model: 'users',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    },
    created_at: {
      allowNull: false,
      type: Sequelize.DATE
    },
    updated_at: {
      allowNull: false,
      type: Sequelize.DATE
    }
  }, {
    uniqueKeys: {
      unique: {
        fields: ['team_id', 'user_id']
      }
    }
  });

exports.down = queryInterface =>
  queryInterface.dropTable('roles');
