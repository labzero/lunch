import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import hasRole from '../../../helpers/hasRole';
import loadComponent from '../../../helpers/loadComponent';
import redirectToLogin from '../../helpers/redirectToLogin';
import render404 from '../../helpers/render404';

/* eslint-disable global-require */

export default {

  path: '/',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = state.team;

    if (user.id) {
      if (team.id && hasRole(user, team)) {
        const HomeContainer = await loadComponent(
          () => require.ensure([], require => require('./HomeContainer').default, 'home')
        );

        return {
          chunk: 'home',
          component: (
            <LayoutContainer path={context.url}>
              <HomeContainer />
            </LayoutContainer>
          ),
          map: true
        };
      }
      return render404;
    }

    return redirectToLogin(context);
  },
};
