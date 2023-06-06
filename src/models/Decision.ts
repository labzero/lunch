import {
  BelongsTo,
  Column,
  ForeignKey,
  Index,
  Model,
  Scopes,
  Table,
} from "sequelize-typescript";
import dayjs from "dayjs";
import { Op } from "sequelize";
import Restaurant from "./Restaurant";
import Team from "./Team";

@Scopes(() => ({
  fromToday: () => ({
    where: {
      createdAt: {
        [Op.gt]: dayjs().subtract(12, "hours").toDate(),
      },
    },
  }),
}))
@Table({ modelName: "decision" })
class Decision extends Model {
  @ForeignKey(() => Restaurant)
  @Index
  @Column({ allowNull: false, onDelete: "cascade" })
  restaurantId: number;

  @BelongsTo(() => Restaurant)
  restaurant: Awaited<Restaurant>;

  @ForeignKey(() => Team)
  @Column
  teamId: number;

  @Index
  @Column
  createdAt: Date;
}

export default Decision;
