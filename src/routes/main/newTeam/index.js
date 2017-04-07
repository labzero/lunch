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

const title = 'New Team';

export default {

  path: '/new-team',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      const NewTeamContainer = await loadComponent(
        () => require.ensure([], require => require('./NewTeamContainer').default, 'new-team')
      );

      return {
        title,
        chunk: 'new-team',
        component: (
          <LayoutContainer path={context.url}>
            <NewTeamContainer title={title} />
          </LayoutContainer>
        ),
        map: true
      };
    }

    return redirectToLogin(context);
  },

};
