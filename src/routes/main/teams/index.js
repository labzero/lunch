import React from 'react';
import TeamsContainer from './TeamsContainer';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import redirectToLogin from '../../helpers/redirectToLogin';

/* eslint-disable global-require */

export default {

  path: '/teams',

  action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      return {
        component: <LayoutContainer path={context.path}><TeamsContainer /></LayoutContainer>,
      };
    }

    return redirectToLogin(context);
  },
};
