import {
  BelongsToMany,
  Column,
  DataType,
  HasMany,
  Index,
  Model,
  Table,
} from "sequelize-typescript";
import User from "./User";
import Role from "./Role";

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
}

export default Team;
