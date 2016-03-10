import { sequelize, DataTypes } from './db';

const Tag = sequelize.define('tag', {
  name: DataTypes.STRING,

  restaurant_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'restaurant',
      key: 'id'
    }
  }
}, { 
  underscored: true
});

export default Tag
