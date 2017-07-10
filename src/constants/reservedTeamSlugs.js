import reservedUsernames from 'reserved-usernames/data.json';

export default [
  ...reservedUsernames,
  'local',
  'localhost',
  'ci',
  'development',
  'production',
  'uat'
];
