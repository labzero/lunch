import React from 'react';
import HomeContainer from './HomeContainer';
import hasRole from '../../../helpers/hasRole';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import redirectToLogin from '../../helpers/redirectToLogin';
import render404 from '../../helpers/render404';

/* eslint-disable global-require */

export default {

  path: '/',

  action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = state.team;

    if (user.id) {
      if (hasRole(user, team)) {
        return {
          component: (
            <LayoutContainer path={context.url}>
              <HomeContainer />
            </LayoutContainer>
          ),
        };
      }
      return render404;
    }

    return redirectToLogin(context);
  },
};
