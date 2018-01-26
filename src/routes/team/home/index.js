import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import hasRole from '../../../helpers/hasRole';
import renderIfHasName from '../../helpers/renderIfHasName';
import render404 from '../../helpers/render404';
import HomeContainer from './HomeContainer';

/* eslint-disable global-require */

export default (context) => {
  const state = context.store.getState();
  const user = state.user;
  const team = state.team;

  return renderIfHasName(context, () => {
    if (team.id && hasRole(user, team)) {
      return {
        chunks: ['home'],
        component: (
          <LayoutContainer path={context.pathname}>
            <HomeContainer />
          </LayoutContainer>
        ),
        map: true
      };
    }
    return render404;
  });
};
