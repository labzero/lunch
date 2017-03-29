import { sequelize, DataTypes } from './db';

const Tag = sequelize.define('tag', {
  name: DataTypes.STRING,
  team_id: DataTypes.INTEGER
}, {
  underscored: true
});

export default Tag;
