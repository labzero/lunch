import { sequelize } from './db';
import Vote from './Vote';
import User from './User';
import RestaurantTag from './RestaurantTag';
import Tag from './Tag';
import Restaurant from './Restaurant';

Tag.addScope('orderedByRestaurant', {
  distinct: 'id',
  attributes: [
    'id',
    'name',
    [sequelize.fn('count', sequelize.col('restaurants_tags.restaurant_id')), 'restaurant_count']
  ],
  include: [
    {
      attributes: [],
      model: RestaurantTag,
      required: false
    }
  ],
  group: ['tag.id'],
  order: 'restaurant_count DESC'
});

Restaurant.addScope('withTagIds', {
  attributes: {
    include: [
      [sequelize.literal('COUNT(*) OVER(PARTITION BY "restaurant"."id")'), 'vote_count'],
      [sequelize.literal(
        'ARRAY(SELECT "tag_id" from "restaurants_tags" ' +
        'where "restaurants_tags"."restaurant_id" = "restaurant"."id")'
      ), 'tags']
    ]
  },
  include: [
    {
      model: Vote.scope('fromToday'),
      required: false
    }
  ],
  order: 'vote_count DESC, votes.created_at DESC NULLS LAST, name ASC'
});

Restaurant.hasMany(Vote);
Restaurant.belongsToMany(Tag, {
  through: 'restaurants_tags'
});
Restaurant.hasMany(RestaurantTag);

User.hasMany(Vote);

Tag.belongsToMany(Restaurant, {
  through: 'restaurants_tags'
});
Tag.hasMany(RestaurantTag);

RestaurantTag.belongsTo(Restaurant);
RestaurantTag.belongsTo(Tag);

export { Vote, User, RestaurantTag, Tag, Restaurant };
