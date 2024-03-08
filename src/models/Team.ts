import {
  BelongsToMany,
  Column,
  DataType,
  HasMany,
  Index,
  Model,
  Table,
} from "sequelize-typescript";
import { TeamWithAdminData } from "src/interfaces";
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
      order: [["createdAt", "DESC"]],
      include: [
        {
          model: Role,
          attributes: ["userId"],
        },
        {
          model: Restaurant,
          attributes: ["id"],
          include: [
            {
              model: Vote,
              attributes: ["createdAt"],
              order: [["createdAt", "DESC"]],
              limit: 1,
            },
          ],
        },
      ],
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
