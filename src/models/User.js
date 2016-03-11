import { sequelize, DataTypes } from './db';
import Vote from './Vote';

const User = sequelize.define('user', {
  google_id: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING
}, {
  underscored: true
});
User.hasMany(Vote);

export default User;
