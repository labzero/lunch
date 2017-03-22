/* eslint-disable global-require */

export default {

  path: '/:slug',

  children: [
    require('./home').default,
    require('./team').default,
  ]
};
