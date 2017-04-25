exports.up = (queryInterface, Sequelize) => queryInterface.createTable('invitations', {
  id: {
    allowNull: false,
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  email: {
    type: Sequelize.STRING,
    allowNull: false,
    unique: true
  },
  created_at: {
    type: Sequelize.DATE,
    allowNull: false
  },
  updated_at: {
    type: Sequelize.DATE,
    allowNull: false
  },
  confirmed_at: {
    type: Sequelize.DATE
  },
  confirmation_token: {
    type: Sequelize.STRING,
    unique: true
  },
  confirmation_sent_at: {
    type: Sequelize.DATE
  }
});

exports.down = queryInterface => queryInterface.dropTable('invitations');
