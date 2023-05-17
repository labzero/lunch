import { sequelize } from "./db";
import Decision from "./Decision";
import Invitation from "./Invitation";
import Restaurant from "./Restaurant";
import RestaurantTag from "./RestaurantTag";
import Role from "./Role";
import Tag from "./Tag";
import Team from "./Team";
import User from "./User";
import Vote from "./Vote";

Tag.addScope("orderedByRestaurant", {
  attributes: [
    "id",
    "name",
    [
      sequelize.fn("count", sequelize.col("restaurantsTags.restaurantId")),
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
});

Restaurant.hasMany(Vote);
Restaurant.hasMany(Decision);
Restaurant.belongsToMany(Tag, {
  through: RestaurantTag,
});

Role.belongsTo(User);
Role.belongsTo(Team);

User.hasMany(Vote);
User.hasMany(Role);
User.belongsToMany(Team, {
  through: "role",
});

Tag.belongsToMany(Restaurant, {
  through: RestaurantTag,
});
Tag.hasMany(RestaurantTag);

Team.hasMany(Role);
Team.belongsToMany(User, {
  through: "role",
});

RestaurantTag.belongsTo(Restaurant);
RestaurantTag.belongsTo(Tag);

export {
  Decision,
  Invitation,
  Restaurant,
  RestaurantTag,
  Role,
  Tag,
  Team,
  User,
  Vote,
};
