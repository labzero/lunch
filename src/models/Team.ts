import {
  BelongsToMany,
  Column,
  DataType,
  HasMany,
  Index,
  Model,
  Table,
} from "sequelize-typescript";
import { sequelize } from "../db";
import User from "./User";
import Role from "./Role";
import Restaurant from "./Restaurant";
import Vote from "./Vote";

@Table({ modelName: "team" })
class Team extends Model {
  static findAllForUser = (user: User) =>
    Team.findAll({
      order: [["createdAt", "ASC"]],
      where: { id: user.roles.map((r) => r.teamId) },
      attributes: {
        exclude: ["createdAt", "updatedAt"],
      },
    });

  static findAllWithAdminData = () =>
    Team.findAll({
      attributes: [
        "name",
        "slug",
        "createdAt",
        [
          sequelize.fn(
            "MAX",
            sequelize.col('"restaurants->votes"."createdAt"')
          ),
          "recentVoteCreatedAt",
        ],
        [
          sequelize.fn("COUNT", sequelize.literal('DISTINCT roles."id"')),
          "roleCount",
        ],
      ],
      include: [
        {
          model: Restaurant,
          as: "restaurants",
          attributes: [],
          include: [
            {
              model: Vote,
              as: "votes",
              attributes: [],
            },
          ],
        },
        {
          model: Role,
          as: "roles",
          attributes: [],
        },
      ],
      group: ["team.id", 'team."name"', 'team."slug"', 'team."createdAt"'],
      order: sequelize.literal(
        'CASE WHEN MAX("restaurants->votes"."createdAt") IS NULL THEN 1 ELSE 0 END, "recentVoteCreatedAt" DESC'
      ),
    });

  @Column
  name: string;

  @Column({ allowNull: false, type: DataType.STRING({ length: 63 }) })
  slug: string;

  @Column
  defaultZoom: number;

  @Column
  sortDuration: number;

  @Column({ allowNull: false, type: DataType.DOUBLE })
  lat: number;

  @Column({ allowNull: false, type: DataType.DOUBLE })
  lng: number;

  @Column
  address: string;

  @Index
  createdAt: Date;

  @HasMany(() => Role)
  roles: Role[];

  @BelongsToMany(() => User, () => Role)
  users: User[];

  @HasMany(() => Restaurant)
  restaurants: Restaurant[];
}

export default Team;
