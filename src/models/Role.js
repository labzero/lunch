import { sequelize, DataTypes } from './db';

const Role = sequelize.define(
  'role',
  {
    type: {
      allowNull: false,
      type: DataTypes.ENUM('guest', 'member', 'owner'),
    },
    userId: {
      type: DataTypes.INTEGER,
      references: {
        model: 'user',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    },
    teamId: {
      type: DataTypes.INTEGER,
      references: {
        model: 'team',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    }
  },
  {
    uniqueKeys: {
      unique: {
        fields: ['userId', 'teamId']
      }
    },
  },
  {
    indexes: [
      {
        fields: ['userId', 'teamId']
      }
    ]
  }
);

export default Role;
