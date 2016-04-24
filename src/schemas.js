import { Schema, arrayOf } from 'normalizr';

export const restaurant = new Schema('restaurants');
export const vote = new Schema('votes');
export const tag = new Schema('tags');
export const user = new Schema('users');
export const whitelistEmail = new Schema('whitelistEmails');

restaurant.define({
  votes: arrayOf(vote)
});
