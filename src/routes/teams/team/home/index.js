import React from 'react';
import HomeContainer from './HomeContainer';
import LayoutContainer from '../../../../components/Layout/LayoutContainer';
import redirectToLogin from '../../../../helpers/redirectToLogin';

/* eslint-disable global-require */

export default {

  path: '/',

  action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      return {
        title: 'Lunch',
        component: (
          <LayoutContainer>
            <HomeContainer teamSlug={context.params.slug} />
          </LayoutContainer>
        ),
      };
    }

    return redirectToLogin(context);
  },
};
