import { sequelize, DataTypes } from './db';

const User = sequelize.define('user', {
  googleId: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  encryptedPassword: DataTypes.STRING,
  resetPasswordToken: DataTypes.STRING,
  resetPasswordSentAt: DataTypes.DATE,
  confirmationToken: DataTypes.STRING,
  confirmationSentAt: DataTypes.DATE,
  confirmedAt: DataTypes.DATE,
  nameChanged: DataTypes.BOOLEAN,
  superuser: DataTypes.BOOLEAN
}, {
  scopes: {
    withTeamRole: (teamId, extraAttributes) => ({
      attributes: [
        'name',
        'id',
        [sequelize.literal(`(SELECT "roles"."type" FROM "roles"
          WHERE "roles"."teamId" = ${teamId} AND "roles"."userId" = "user"."id")`),
        'type']
      ].concat(extraAttributes || [])
    })
  },
});

User.prototype.resetPasswordValid = function resetPasswordValid() {
  return new Date() - this.get('resetPasswordSentAt') < 60 * 60 * 1000 * 24;
};

export default User;
