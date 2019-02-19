const db = require('../../src/models/db');

exports.up = (queryInterface, Sequelize) => {
  const User = db.sequelize.define('user', {
    google_id: Sequelize.STRING,
    name: Sequelize.STRING,
    email: Sequelize.STRING
  }, {
    underscored: true
  });

  const Team = db.sequelize.define('team', {
    name: Sequelize.STRING,
  }, {
    underscored: true
  });

  return queryInterface.createTable('roles', {
    id: {
      allowNull: false,
      autoIncrement: true,
      primaryKey: true,
      type: Sequelize.INTEGER
    },
    type: {
      allowNull: false,
      type: Sequelize.ENUM('guest', 'member', 'owner'),
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
  })
    .then(() => User.findAll())
    .then((users) => Team.findOne({ where: { name: 'Lab Zero' } }).then(team => {
      const Role = db.sequelize.define('role', {
        type: {
          allowNull: false,
          type: Sequelize.ENUM('guest', 'member', 'owner'),
        },
        user_id: {
          type: Sequelize.INTEGER,
          references: {
            model: 'user',
            key: 'id'
          },
          allowNull: false,
          onDelete: 'cascade'
        },
        team_id: {
          type: Sequelize.INTEGER,
          references: {
            model: 'team',
            key: 'id'
          },
          allowNull: false,
          onDelete: 'cascade'
        }
      }, {
        uniqueKeys: {
          unique: {
            fields: ['user_id', 'team_id']
          }
        },
        underscored: true
      });

      return Promise.all(users.map(user => Role.create({
        team_id: team.id,
        user_id: user.id,
        type: user.email.match(/@labzero\.com$/) ? 'member' : 'guest'
      })));
    }));
};

exports.down = queryInterface => queryInterface.dropTable('roles').then(() => db.sequelize.query('DROP TYPE enum_roles_type'));
