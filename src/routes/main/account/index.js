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

const title = 'Account';

export default {

  path: '/account',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      const AccountContainer = await loadComponent(
        () => require.ensure([], require => require('./AccountContainer').default, 'account')
      );

      return {
        title,
        chunk: 'account',
        component: (
          <LayoutContainer path={context.url}>
            <AccountContainer />
          </LayoutContainer>
        )
      };
    }

    return redirectToLogin(context);
  },

};
