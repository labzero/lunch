import { InferAttributes, InferCreationAttributes, Model, NonAttribute, ProjectionAlias } from 'sequelize';
import { Literal } from 'sequelize/types/utils';
import { sequelize, DataTypes } from './db';
import Role from './Role';

const teamUserAttributes = (teamId: number | string, extraAttributes: (string | ProjectionAlias)[]) => extraAttributes.concat([
    'name',
    'id',
    [
      sequelize.literal(`(SELECT "roles"."type" FROM "roles"
      WHERE "roles"."teamId" = ${teamId} AND "roles"."userId" = "user"."id")`),
      'type',
    ],
  ]);

type FindAttributeOptions = (string | ProjectionAlias)[];

class User extends Model<InferAttributes<User>, InferCreationAttributes<User>> {
  static findAllForTeam = (teamId: number, extraAttributes: FindAttributeOptions) => User.findAll({
    attributes: teamUserAttributes(teamId, extraAttributes),
  });
  static findOneWithRoleType = (id: number, teamId: number, extraAttributes: FindAttributeOptions) => User.findOne({
    attributes: teamUserAttributes(teamId, extraAttributes),
    where: { id },
  });
  resetPasswordValid() {
    const resetPasswordSentAt = this.get('resetPasswordSentAt');
    if (resetPasswordSentAt) {
      return new Date().getTime() - resetPasswordSentAt.getTime() < 60 * 60 * 1000 * 24;
    }
    return false;
  };
  static getSessionUser = (id: number | string) => User.findOne({
    attributes: ['id', 'name', 'email', 'superuser'],
    where: { id },
    include: [
      {
        model: Role,
        required: false,
        attributes: ['type', 'teamId', 'userId'],
      },
    ],
  });

  declare id: number;
  declare googleId: string;
  declare name: string;
  declare email: string;
  declare encryptedPassword?: string;
  declare resetPasswordToken?: string;
  declare resetPasswordSentAt?: Date;
  declare confirmationToken?: string;
  declare confirmationSentAt?: Date;
  declare confirmedAt?: Date;
  declare nameChanged: boolean;
  declare superuser: boolean;

  declare roles: NonAttribute<Role[]>;
}

User.init({
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
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
  modelName: 'user',
  scopes: {
    withTeamRole: (teamId: string, extraAttributes: string[]) => ({
      attributes: [
        'name',
        'id',
        [sequelize.literal(`(SELECT "roles"."type" FROM "roles"
          WHERE "roles"."teamId" = ${teamId} AND "roles"."userId" = "user"."id")`),
        'type'] as [Literal, string]
      ].concat(extraAttributes || [])
    })
  },
  sequelize,
});

export default User;
