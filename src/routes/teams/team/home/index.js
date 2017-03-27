import React from 'react';
import HomeContainer from './HomeContainer';
import hasRole from '../../../../helpers/hasRole';
import LayoutContainer from '../../../../components/Layout/LayoutContainer';
import { getTeamBySlug } from '../../../../selectors/teams';
import redirectToLogin from '../../../helpers/redirectToLogin';
import render404 from '../../../helpers/render404';

/* eslint-disable global-require */

export default {

  path: '/',

  action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = getTeamBySlug(state, context.params.slug);

    if (user.id) {
      if (hasRole(user, team)) {
        return {
          component: (
            <LayoutContainer path={context.path} teamSlug={context.params.slug}>
              <HomeContainer teamSlug={context.params.slug} />
            </LayoutContainer>
          ),
        };
      }
      return render404;
    }

    return redirectToLogin(context);
  },
};
