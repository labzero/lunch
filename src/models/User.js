import { sequelize, DataTypes } from './db';

const User = sequelize.define('user', {
  google_id: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  encrypted_password: DataTypes.STRING,
  reset_password_token: DataTypes.STRING,
  reset_password_sent_at: DataTypes.DATE,
  confirmation_token: DataTypes.STRING,
  confirmation_sent_at: DataTypes.DATE,
  confirmed_at: DataTypes.DATE,
  name_changed: DataTypes.BOOLEAN,
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

User.prototype.resetPasswordValid = function resetPasswordValid() {
  return new Date() - this.get('reset_password_sent_at') < 60 * 60 * 1000 * 24;
};

export default User;
