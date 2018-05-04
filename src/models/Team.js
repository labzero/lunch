import { sequelize, DataTypes } from './db';

const Team = sequelize.define('team', {
  name: DataTypes.STRING,
  slug: {
    allowNull: false,
    type: DataTypes.STRING(63)
  },
  default_zoom: DataTypes.INTEGER,
  sort_duration: DataTypes.INTEGER,
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
},
{
  indexes: [
    {
      fields: ['created_at']
    }
  ]
});

export default Team;
