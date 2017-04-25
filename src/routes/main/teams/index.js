import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import loadComponent from '../../../helpers/loadComponent';
import renderIfHasName from '../../helpers/renderIfHasName';

/* eslint-disable global-require */

export default {

  path: '/teams',

  async action(context) {
    return renderIfHasName(context, async () => {
      const TeamsContainer = await loadComponent(
        () => require.ensure([], require => require('./TeamsContainer').default, 'teams')
      );

      return {
        chunk: 'teams',
        component: <LayoutContainer path={context.path}><TeamsContainer /></LayoutContainer>,
      };
    });
  },
};
