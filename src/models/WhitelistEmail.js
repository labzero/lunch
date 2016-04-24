import { sequelize, DataTypes } from './db';

const WhitelistEmail = sequelize.define('whitelist_email', {
  email: DataTypes.STRING
}, {
  underscored: true
});

export default WhitelistEmail;
