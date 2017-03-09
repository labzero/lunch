import { schema } from 'normalizr';

export const vote = new schema.Entity('votes');
export const restaurant = new schema.Entity('restaurants', {
  votes: [vote]
});
export const tag = new schema.Entity('tags');
export const user = new schema.Entity('users');
export const whitelistEmail = new schema.Entity('whitelistEmails');
