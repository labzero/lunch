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
    [
      sequelize.fn('count', sequelize.col('restaurantsTags.restaurantId')),
      'restaurant_count',
    ],
  ],
  include: [
    {
      attributes: [],
      model: RestaurantTag,
      required: false,
    },
  ],
  group: ['tag.id'],
  order: [sequelize.literal('restaurant_count DESC')],
});

Team.findAllForUser = (user) => Team.findAll({
  order: [['createdAt', 'ASC']],
  where: { id: user.roles.map((r) => r.teamId) },
  attributes: {
    exclude: ['createdAt', 'updatedAt'],
  },
});

// eslint-disable-next-line camelcase
Restaurant.findAllWithTagIds = ({ teamId }) => Team.findByPk(teamId).then((team) => Restaurant.findAll({
  attributes: {
    include: [
      [
        sequelize.literal(`ARRAY(SELECT "tagId" from "restaurantsTags"
            where "restaurantsTags"."restaurantId" = "restaurant"."id")`),
        'tags',
      ],
      [
        sequelize.literal(`(SELECT COUNT(*) from "votes" as "allVotes"
            where "allVotes"."restaurantId" = "restaurant"."id"
            and "allVotes"."createdAt" >= CURRENT_DATE - INTERVAL '${team.sortDuration} days')`),
        'all_vote_count',
      ],
      [
        sequelize.literal(`(SELECT COUNT(*) from "decisions" as "allDecisions"
            where "allDecisions"."restaurantId" = "restaurant"."id"
            and "allDecisions"."createdAt" >= CURRENT_DATE - INTERVAL '${team.sortDuration} days')`),
        'all_decision_count',
      ],
    ],
    exclude: ['updatedAt'],
  },
  include: [
    {
      model: Vote.scope('fromToday'),
      required: false,
      attributes: ['id', 'userId', 'restaurantId', 'createdAt'],
    },
    {
      model: Decision.scope('fromToday'),
      required: false,
      attributes: ['id'],
    },
  ],
  order: [
    [Restaurant.associations.decisions, 'id', 'NULLS LAST'], // decision of the day
    sequelize.literal(
      '(COUNT(*) OVER(PARTITION BY "restaurant"."id")) DESC'
    ), // number of votes
    sequelize.literal(
      '(SELECT CASE WHEN "votes"."id" IS NULL THEN 1 ELSE 0 END)'
    ), // votes vs. no votes
    sequelize.literal('all_decision_count ASC'), // past decisions on bottom
    sequelize.literal('all_vote_count DESC'), // past votes on top
    ['name', 'ASC'], // alphabetical
  ],
  where: {
    // eslint-disable-next-line camelcase
    teamId,
  },
}));

const teamUserAttributes = (teamId, extraAttributes) => ({
  attributes: extraAttributes.concat([
    'name',
    'id',
    [
      sequelize.literal(`(SELECT "roles"."type" FROM "roles"
      WHERE "roles"."teamId" = ${teamId} AND "roles"."userId" = "user"."id")`),
      'type',
    ],
  ]),
});

User.findAllForTeam = (teamId, extraAttributes) => User.findAll({
  attributes: teamUserAttributes(teamId, extraAttributes),
});

User.findOneWithRoleType = (id, teamId, extraAttributes) => User.findOne({
  attributes: teamUserAttributes(teamId, extraAttributes),
  where: { id },
});

User.getSessionUser = (id) => User.findOne({
  attributes: ['id', 'name', 'email', 'superuser'],
  where: { id },
  include: [
    {
      model: Role,
      required: false,
      attributes: ['type', 'teamId', 'userId'],
    },
  ],
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
  through: 'role',
});

Tag.belongsToMany(Restaurant, {
  through: RestaurantTag,
});
Tag.hasMany(RestaurantTag);

Team.hasMany(Role);
Team.belongsToMany(User, {
  through: 'role',
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
