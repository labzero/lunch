import { sequelize, DataTypes } from './db';

const Restaurant = sequelize.define('restaurant', {
  name: DataTypes.STRING,
  address: DataTypes.STRING,
  lat: DataTypes.FLOAT,
  lng: DataTypes.FLOAT,
  place_id: DataTypes.STRING
}, {
  instanceMethods: {
    tagIds: () => this.getTags().map(tag => tag.get('id'))
  },
  underscored: true
});

export default Restaurant;
