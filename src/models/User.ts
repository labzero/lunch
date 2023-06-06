import {
  BelongsToMany,
  Column,
  DataType,
  HasMany,
  Model,
  Scopes,
  Table,
} from "sequelize-typescript";
import { ProjectionAlias } from "sequelize";
import { Literal } from "sequelize/types/utils";
import { sequelize } from "../db";
import Role from "./Role";
import Vote from "./Vote";
import Team from "./Team";

const teamUserAttributes = (
  teamId: number | string,
  extraAttributes: (string | ProjectionAlias)[]
) =>
  extraAttributes.concat([
    "name",
    "id",
    [
      sequelize.literal(`(SELECT "roles"."type" FROM "roles"
      WHERE "roles"."teamId" = ${teamId} AND "roles"."userId" = "user"."id")`),
      "type",
    ],
  ]);

type FindAttributeOptions = (string | ProjectionAlias)[];

@Scopes(() => ({
  withTeamRole: (teamId: string, extraAttributes: string[]) => ({
    attributes: [
      "name",
      "id",
      [
        sequelize.literal(`(SELECT "roles"."type" FROM "roles"
      WHERE "roles"."teamId" = ${teamId} AND "roles"."userId" = "user"."id")`),
        "type",
      ] as [Literal, string],
    ].concat(extraAttributes || []),
  }),
}))
@Table({ modelName: "user" })
class User extends Model {
  static findAllForTeam = (
    teamId: number,
    extraAttributes: FindAttributeOptions
  ) =>
    User.findAll({
      attributes: teamUserAttributes(teamId, extraAttributes),
    });

  static findOneWithRoleType = (
    id: number,
    teamId: number,
    extraAttributes: FindAttributeOptions
  ) =>
    User.findOne({
      attributes: teamUserAttributes(teamId, extraAttributes),
      where: { id },
    });

  resetPasswordValid() {
    const resetPasswordSentAt = this.get("resetPasswordSentAt");
    if (resetPasswordSentAt) {
      return (
        new Date().getTime() - resetPasswordSentAt.getTime() <
        60 * 60 * 1000 * 24
      );
    }
    return false;
  }

  static getSessionUser = (id: number) =>
    User.findOne({
      attributes: ["id", "name", "email", "superuser"],
      where: { id },
      include: [
        {
          model: Role,
          required: false,
          attributes: ["type", "teamId", "userId"],
        },
      ],
    });

  @Column
  googleId: string;

  @Column
  name: string;

  @Column({ type: DataType.CITEXT })
  email: string;

  @Column
  encryptedPassword?: string;

  @Column
  resetPasswordToken?: string;

  @Column
  resetPasswordSentAt?: Date;

  @Column
  confirmationToken?: string;

  @Column
  confirmationSentAt?: Date;

  @Column
  confirmedAt?: Date;

  @Column
  nameChanged: boolean;

  @Column
  superuser: boolean;

  @HasMany(() => Vote)
  votes: Vote[];

  @HasMany(() => Role)
  roles: Role[];

  @BelongsToMany(() => Team, () => Role)
  teams: Team[];
}

export default User;
