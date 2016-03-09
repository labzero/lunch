import Sequelize from 'sequelize';
import sequelize from './sequelize';

const User = sequelize.define('user', {
  google_id: Sequelize.STRING,
  name: Sequelize.STRING,
  email: Sequelize.STRING
}, { underscored: true });

export default User;
