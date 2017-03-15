import React from 'react';
import TeamsContainer from './TeamsContainer';
import LayoutContainer from '../../containers/LayoutContainer';

/* eslint-disable global-require */

export default {

  path: '/teams',

  children: [
    require('./team').default,
  ],

  action() {
    return {
      title: 'Lunch',
      component: <LayoutContainer><TeamsContainer /></LayoutContainer>,
    };
  },
};
