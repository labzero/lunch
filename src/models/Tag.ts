import {
  BelongsToMany,
  Column,
  DataType,
  ForeignKey,
  HasMany,
  Model,
  Scopes,
  Table,
} from "sequelize-typescript";
import { sequelize } from "../db";
import Restaurant from "./Restaurant";
import RestaurantTag from "./RestaurantTag";
import Team from "./Team";

@Scopes(() => ({
  orderedByRestaurant: {
    attributes: [
      "id",
      "name",
      [
        sequelize.fn("count", sequelize.col("restaurantTags.restaurantId")),
        "restaurant_count",
      ],
    ],
    include: [
      {
        attributes: [],
        model: RestaurantTag,
        required: false,
      },
    ],
    group: ["tag.id"],
    order: [sequelize.literal("restaurant_count DESC")],
  },
}))
@Table({ modelName: "tag" })
class Tag extends Model {
  @Column(DataType.STRING)
  name: string;

  @ForeignKey(() => Team)
  @Column(DataType.INTEGER)
  teamId: number;

  @HasMany(() => RestaurantTag)
  restaurantTags: RestaurantTag[];

  @BelongsToMany(() => Restaurant, () => RestaurantTag)
  restaurants: Restaurant[];
}

export default Tag;
