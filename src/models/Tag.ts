import { sequelize, DataTypes } from './db';

const Tag = sequelize.define('tag', {
  name: DataTypes.STRING,
  teamId: DataTypes.INTEGER
});

export default Tag;
