import { sequelize, DataTypes } from './db';

const Team = sequelize.define(
  'team',
  {
    name: DataTypes.STRING,
    slug: {
      allowNull: false,
      type: DataTypes.STRING(63)
    },
    defaultZoom: DataTypes.INTEGER,
    sortDuration: DataTypes.INTEGER,
    lat: {
      allowNull: false,
      type: DataTypes.DOUBLE
    },
    lng: {
      allowNull: false,
      type: DataTypes.DOUBLE
    },
    address: DataTypes.STRING
  },
  undefined,
  {
    indexes: [
      {
        fields: ['createdAt']
      }
    ]
  }
);

export default Team;
