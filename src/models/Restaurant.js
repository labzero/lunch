import moment from 'moment';
import Base from './Base';
import Vote from './Vote';

const Restaurant = Base.extend({
  tableName: 'restaurants',
  hidden: ['name'],
  votes() { return this.hasMany(Vote); },
  virtuals: {
    votesFromToday() {
      return this.votes().where('created_at', '>', moment().subtract(12, 'hours').toDate());
    }
  }
});

export default Restaurant;
