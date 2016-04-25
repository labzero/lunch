import { sequelize, DataTypes } from './db';

const WhitelistEmail = sequelize.define('whitelist_email', {
  email: {
    type: DataTypes.STRING,
    unique: true
  }
}, {
  underscored: true
});

export default WhitelistEmail;
