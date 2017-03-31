import { sequelize, DataTypes } from './db';

const User = sequelize.define('user', {
  google_id: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  superuser: DataTypes.BOOLEAN
}, {
  scopes: {
    withTeamRole: (teamId, extraAttributes) => ({
      attributes: [
        'name',
        'id',
        [sequelize.literal(`(SELECT "roles"."type" FROM "roles"
          WHERE "roles"."team_id" = ${teamId} AND "roles"."user_id" = "user"."id")`),
          'type']
      ].concat(extraAttributes || [])
    })
  },
  underscored: true
});

export default User;
