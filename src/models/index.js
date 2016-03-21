import { sequelize, DataTypes } from './db';
import moment from 'moment';

/* Vote */

export const Vote = sequelize.define('vote',
  {
    user_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'user',
        key: 'id'
      },
      allowNull: false
    },

    restaurant_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'restaurant',
        key: 'id'
      },
      allowNull: false
    }
  },
  {
    scopes: {
      fromToday: () => ({
        where: {
          created_at: {
            $gt: moment().subtract(12, 'hours').toDate()
          }
        }
      })
    },
    underscored: true
  }
);

/* User */

export const User = sequelize.define('user', {
  google_id: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING
}, {
  underscored: true
});

/* RestaurantTag */

export const RestaurantTag = sequelize.define('restaurants_tags', {
  restaurant_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'restaurant',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  },
  tag_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'tag',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  }
}, {
  uniqueKeys: {
    unique: {
      fields: ['restaurant_id', 'tag_id']
    }
  },
  underscored: true
});
RestaurantTag.removeAttribute('id');

/* Tag */

export const Tag = sequelize.define('tag', {
  name: DataTypes.STRING
}, {
  scopes: {
    orderedByRestaurant: {
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
    }
  },
  underscored: true
});

/* Restaurant */

export const Restaurant = sequelize.define('restaurant', {
  name: DataTypes.STRING,
  address: DataTypes.STRING,
  lat: DataTypes.FLOAT,
  lng: DataTypes.FLOAT,
  place_id: DataTypes.STRING
}, {
  classMethods: {
    findAllWithTagIds: () =>
      Restaurant
        .findAll({
          include: [
            {
              model: Vote.scope('fromToday'),
              required: false
            },
            {
              model: Tag,
              attributes: ['id'],
              through: {
                attributes: []
              }
            }
          ]
        })
        .then(all =>
          all.map(inst =>
            Object.assign({}, inst.toJSON(), {
              tags: inst.tags.map(tag =>
                tag.id
              )
            })
          )
        )
  },
  defaultScope: {
    order: 'votes.created_at ASC, created_at DESC'
  },
  instanceMethods: {
    tagIds: () => this.getTags().map(tag => tag.get('id'))
  },
  underscored: true
});

/* Associations */

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
