import { sequelize, DataTypes } from './db';

const Team = sequelize.define('team', {
  name: DataTypes.STRING,
  slug: DataTypes.STRING,
}, {
  underscored: true
});

export default Team;
