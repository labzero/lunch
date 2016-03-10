import { sequelize, DataTypes } from './db';
import Vote from './Vote';
import Tag from './Tag';

const Restaurant = sequelize.define('restaurant', {
  name: DataTypes.STRING,
  address: DataTypes.STRING,
  lat: DataTypes.FLOAT,
  lng: DataTypes.FLOAT,
  place_id: DataTypes.STRING
}, {
  defaultScope: {
    order: 'votes.created_at ASC, created_at DESC'
  },
  underscored: true
});
Restaurant.hasMany(Vote);
Restaurant.hasMany(Tag);
  
export default Restaurant;
