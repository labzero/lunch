/* eslint-disable global-require */

export default {

  path: '/:slug',

  children: [
    require('./home').default,
    require('./tags').default,
    require('./team').default,
  ]
};
