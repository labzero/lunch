import Base from './Base';
import Restaurant from './Restaurant';
import User from './User';

const Vote = Base.extend({
  tableName: 'votes',
  restaurant: () => this.belongsTo(Restaurant),
  user: () => this.belongsTo(User),
});

export default Vote;
