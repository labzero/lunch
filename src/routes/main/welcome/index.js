/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import loadComponent from '../../../helpers/loadComponent';
import redirectToLogin from '../../helpers/redirectToLogin';

const title = 'Welcome!';

export default {

  path: '/welcome',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      const WelcomeContainer = await loadComponent(
        () => require.ensure([], require => require('./WelcomeContainer').default, 'welcome')
      );

      return {
        title,
        chunk: 'welcome',
        component: (
          <LayoutContainer path={context.url}>
            <WelcomeContainer next={context.query.next} team={context.query.team} />
          </LayoutContainer>
        )
      };
    }

    return redirectToLogin(context);
  },

};
