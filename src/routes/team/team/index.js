/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import hasRole from '../../../helpers/hasRole';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import redirectToLogin from '../../helpers/redirectToLogin';
import render404 from '../../helpers/render404';

const title = 'Team';

export default {

  path: '/team',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = state.team;

    if (user.id) {
      if (hasRole(user, team, 'member')) {
        let TeamContainer;
        try {
          TeamContainer = await require.ensure([], require => require('./TeamContainer').default, 'team');
        } catch (err) {
          TeamContainer = () => null;
        }

        return {
          title,
          // chunk: 'team',
          component: (
            <LayoutContainer path={context.url}>
              <TeamContainer title={title} />
            </LayoutContainer>
          ),
        };
      }
      return render404;
    }

    return redirectToLogin(context);
  },

};
