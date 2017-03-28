import { sequelize, DataTypes } from './db';

const Team = sequelize.define('team', {
  name: DataTypes.STRING,
  slug: {
    allowNull: false,
    type: DataTypes.STRING(63)
  },
  lat: {
    allowNull: false,
    type: DataTypes.DOUBLE
  },
  lng: {
    allowNull: false,
    type: DataTypes.DOUBLE
  },
  address: DataTypes.STRING
}, {
  underscored: true
});

export default Team;
