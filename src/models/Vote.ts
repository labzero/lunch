import dayjs from "dayjs";
import {
  InferAttributes,
  InferCreationAttributes,
  Model,
  Transaction,
} from "sequelize";
import { sequelize, DataTypes, Op } from "./db";

class Vote extends Model<InferAttributes<Vote>, InferCreationAttributes<Vote>> {
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

  declare userId: number;
  declare restaurantId: number;
}

Vote.init(
  {
    userId: {
      type: DataTypes.INTEGER,
      references: {
        model: "user",
        key: "id",
      },
      allowNull: false,
    },

    restaurantId: {
      type: DataTypes.INTEGER,
      references: {
        model: "restaurant",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
    },
  },
  {
    indexes: [
      {
        fields: ["createdAt", "restaurantId", "userId"],
      },
    ],
    modelName: "vote",
    scopes: {
      fromToday: () => ({
        where: {
          createdAt: {
            [Op.gt]: dayjs().subtract(12, "hours").toDate(),
          },
        },
      }),
    },
    sequelize,
  }
);

export default Vote;
