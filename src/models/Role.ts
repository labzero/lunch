import {
  BelongsTo,
  Column,
  DataType,
  ForeignKey,
  Index,
  Model,
  Table,
} from "sequelize-typescript";

import type { RoleType } from "../interfaces";
import Team from "./Team";
import User from "./User";

@Table({ modelName: "role" })
class Role extends Model {
  @ForeignKey(() => User)
  @Index({ unique: true })
  @Column({ allowNull: false, onDelete: "cascade" })
  userId: number;

  @BelongsTo(() => User)
  user: Awaited<User>;

  @ForeignKey(() => Team)
  @Index({ unique: true })
  @Column({ allowNull: false, onDelete: "cascade" })
  teamId: number;

  @BelongsTo(() => Team)
  team: Awaited<Team>;

  @Column({ allowNull: false, type: DataType.ENUM("guest", "member", "owner") })
  type: RoleType;
}

export default Role;
