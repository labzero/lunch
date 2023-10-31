import {
  BelongsTo,
  Column,
  DataType,
  ForeignKey,
  Index,
  Model,
  Scopes,
  Table,
} from "sequelize-typescript";
import dayjs from "dayjs";
import { Op, Transaction } from "sequelize";
import User from "./User";
import Restaurant from "./Restaurant";

@Scopes(() => ({
  fromToday: () => ({
    where: {
      createdAt: {
        [Op.gt]: dayjs().subtract(12, "hours").toDate(),
      },
    },
  }),
}))
@Table({ modelName: "vote" })
class Vote extends Model {
  static recentForRestaurantAndUser = (
    restaurantId: number,
    userId: number,
    transaction: Transaction
  ) =>
    Vote.scope("fromToday").count({
      transaction,
      where: {
        userId,
        restaurantId,
      },
    });

  @ForeignKey(() => User)
  @Index
  @Column({ allowNull: false, type: DataType.INTEGER })
  userId: number;

  @BelongsTo(() => User)
  user: Awaited<User>;

  @ForeignKey(() => Restaurant)
  @Index
  @Column({ allowNull: false, onDelete: "cascade", type: DataType.INTEGER })
  restaurantId: number;

  @BelongsTo(() => Restaurant)
  restaurant: Awaited<Restaurant>;

  @Index
  createdAt: Date;
}

export default Vote;
