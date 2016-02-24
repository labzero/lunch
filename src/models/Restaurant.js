import { bookshelf } from '../services/bookshelf';

const Restaurant = bookshelf.Model.extend({
  tableName: 'restaurants'
});

export default Restaurant;
