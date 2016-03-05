import config from '../../knexfile.js';
import knex from 'knex';
import bookshelf from 'bookshelf';
import bookshelfModelBase from 'bookshelf-modelbase';

const knexInst = knex(config[process.env.NODE_ENV]);
const bookshelfInst = bookshelf(knexInst);

bookshelfInst.plugin('virtuals');
bookshelfInst.plugin('visibility');

export default bookshelfModelBase(bookshelfInst);
