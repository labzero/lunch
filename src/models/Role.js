import { sequelize, DataTypes } from './db';

const Role = sequelize.define('role', {
  type: {
    allowNull: false,
    type: DataTypes.ENUM('admin', 'owner'),
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
}, {
  uniqueKeys: {
    unique: {
      fields: ['user_id', 'team_id']
    }
  },
  underscored: true
});

export default Role;
