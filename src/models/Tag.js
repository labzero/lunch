import { sequelize, DataTypes } from './db';

const Tag = sequelize.define('tag', {
  name: DataTypes.STRING
}, {
  underscored: true
});

export default Tag;
