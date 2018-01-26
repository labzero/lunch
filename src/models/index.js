import { sequelize } from './db';
import Decision from './Decision';
import Invitation from './Invitation';
import Restaurant from './Restaurant';
import RestaurantTag from './RestaurantTag';
import Role from './Role';
import Tag from './Tag';
import Team from './Team';
import User from './User';
import Vote from './Vote';

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
  order: [sequelize.literal('restaurant_count DESC')]
});

// eslint-disable-next-line camelcase
Restaurant.findAllWithTagIds = ({ team_id }) =>
  Team.findById(team_id).then(team =>
    Restaurant.findAll({
      attributes: {
        include: [
          [sequelize.literal('COUNT(*) OVER(PARTITION BY "restaurant"."id")'), 'vote_count'],
          [sequelize.literal(`ARRAY(SELECT "tag_id" from "restaurants_tags"
            where "restaurants_tags"."restaurant_id" = "restaurant"."id")`),
            'tags'],
          [sequelize.literal(`(SELECT COUNT(*) from "votes" as "all_votes"
            where "all_votes"."restaurant_id" = "restaurant"."id"
            and "all_votes"."created_at" >= CURRENT_DATE - INTERVAL '${team.sort_duration} days')`),
            'all_vote_count'],
          [sequelize.literal(`(SELECT COUNT(*) from "decisions" as "all_decisions"
            where "all_decisions"."restaurant_id" = "restaurant"."id"
            and "all_decisions"."created_at" >= CURRENT_DATE - INTERVAL '${team.sort_duration} days')`),
            'all_decision_count']
        ],
        exclude: ['updated_at']
      },
      include: [
        {
          model: Vote.scope('fromToday'),
          required: false,
          attributes: ['id', 'user_id', 'restaurant_id', 'created_at']
        },
        {
          model: Decision.scope('fromToday'),
          required: false,
          attributes: ['id']
        }
      ],
      order: [
        [Restaurant.associations.decisions, 'id', 'NULLS LAST'],
        sequelize.literal('vote_count DESC'),
        [Restaurant.associations.votes, 'created_at', 'DESC', 'NULLS LAST'],
        sequelize.literal('all_decision_count ASC'),
        sequelize.literal('all_vote_count DESC'),
        ['name', 'ASC'],
      ],
      where: {
        team_id
      }
    })
  );

const teamUserAttributes = (teamId, extraAttributes) => ({
  attributes: extraAttributes.concat([
    'name',
    'id',
    [sequelize.literal(`(SELECT "roles"."type" FROM "roles"
      WHERE "roles"."team_id" = ${teamId} AND "roles"."user_id" = "user"."id")`),
      'type']
  ])
});

User.findAllForTeam = (teamId, extraAttributes) =>
  User.findAll({
    attributes: teamUserAttributes(teamId, extraAttributes)
  });

User.findOneWithRoleType = (id, teamId, extraAttributes) =>
  User.findOne({
    attributes: teamUserAttributes(teamId, extraAttributes),
    where: { id }
  });

User.getSessionUser = id =>
  User.findOne({
    attributes: ['id', 'name', 'email', 'superuser'],
    where: { id },
    include: [
      {
        model: Role,
        required: false,
        attributes: ['type', 'team_id', 'user_id']
      }
    ]
  });

Restaurant.hasMany(Vote);
Restaurant.hasMany(Decision);
Restaurant.belongsToMany(Tag, {
  through: RestaurantTag
});

Role.belongsTo(User);
Role.belongsTo(Team);

User.hasMany(Vote);
User.hasMany(Role);
User.belongsToMany(Team, {
  through: 'role'
});

Tag.belongsToMany(Restaurant, {
  through: RestaurantTag
});
Tag.hasMany(RestaurantTag);

Team.hasMany(Role);
Team.belongsToMany(User, {
  through: 'role'
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
  Vote
};
