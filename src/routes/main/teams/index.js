import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import loadComponent from '../../../helpers/loadComponent';
import redirectToLogin from '../../helpers/redirectToLogin';

/* eslint-disable global-require */

export default {

  path: '/teams',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      const TeamsContainer = await loadComponent(
        () => require.ensure([], require => require('./TeamsContainer').default, 'teams')
      );

      return {
        chunk: 'teams',
        component: <LayoutContainer path={context.path}><TeamsContainer /></LayoutContainer>,
      };
    }

    return redirectToLogin(context);
  },
};
