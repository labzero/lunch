import { sequelize, DataTypes } from './db';

const Role = sequelize.define(
  'role',
  {
    type: {
      allowNull: false,
      type: DataTypes.ENUM('guest', 'member', 'owner'),
    },
    user_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'user',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    },
    team_id: {
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
        fields: ['user_id', 'team_id']
      }
    },
    underscored: true
  },
  {
    indexes: [
      {
        fields: ['user_id', 'team_id']
      }
    ]
  }
);

export default Role;
