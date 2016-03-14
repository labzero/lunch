import { sequelize, DataTypes } from './db';
import Vote from './Vote';
import Tag from './Tag';

const Restaurant = sequelize.define('restaurant', {
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
              model: Vote,
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
Restaurant.hasMany(Vote.scope('fromToday'));
Restaurant.belongsToMany(Tag, {
  through: 'restaurants_tags'
});

export default Restaurant;
