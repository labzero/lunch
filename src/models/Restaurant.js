import { sequelize, DataTypes } from './db';

const Restaurant = sequelize.define('restaurant', {
  name: DataTypes.STRING,
  address: DataTypes.STRING,
  lat: DataTypes.FLOAT,
  lng: DataTypes.FLOAT,
  place_id: DataTypes.STRING,
  team_id: DataTypes.INTEGER
}, {
  underscored: true
});

export default Restaurant;
