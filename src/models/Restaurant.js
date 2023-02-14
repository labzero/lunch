import { sequelize, DataTypes } from './db';

const Restaurant = sequelize.define('restaurant', {
  name: DataTypes.STRING,
  address: DataTypes.STRING,
  lat: DataTypes.FLOAT,
  lng: DataTypes.FLOAT,
  placeId: DataTypes.STRING,
  teamId: DataTypes.INTEGER
});

export default Restaurant;
