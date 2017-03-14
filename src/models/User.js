import { sequelize, DataTypes } from './db';

const User = sequelize.define('user', {
  google_id: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  superuser: DataTypes.BOOLEAN
}, {
  underscored: true
});

export default User;
