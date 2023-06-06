import {
  BelongsTo,
  Column,
  ForeignKey,
  Index,
  Model,
  PrimaryKey,
  Table,
} from "sequelize-typescript";
import Restaurant from "./Restaurant";
import Tag from "./Tag";

@Table({ modelName: "restaurantsTags" })
class RestaurantTag extends Model {
  @PrimaryKey
  @ForeignKey(() => Restaurant)
  @Index({ unique: true })
  @Column
  restaurantId: number;

  @BelongsTo(() => Restaurant)
  restaurant: Awaited<Restaurant>;

  @PrimaryKey
  @ForeignKey(() => Tag)
  @Index({ unique: true })
  @Column
  tagId: number;

  @BelongsTo(() => Tag)
  tag: Awaited<Tag>;
}

export default RestaurantTag;
