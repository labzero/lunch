import { sequelize, DataTypes } from './db';

const Invitation = sequelize.define('invitation', {
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  confirmed_at: {
    type: DataTypes.DATE
  },
  confirmation_token: {
    type: DataTypes.STRING,
    unique: true
  },
  confirmation_sent_at: {
    type: DataTypes.DATE
  }
}, {
  underscored: true
});

export default Invitation;
