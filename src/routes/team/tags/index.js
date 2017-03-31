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

const title = 'Tags';

export default {

  path: '/tags',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = state.team;

    if (user.id) {
      if (hasRole(user, team)) {
        let TagsContainer;
        try {
          TagsContainer = await require.ensure([], require => require('./TagsContainer').default, 'tags');
        } catch (err) {
          TagsContainer = () => null;
        }

        return {
          title,
          // chunk: 'tags',
          component: (
            <LayoutContainer path={context.url}>
              <TagsContainer title={title} />
            </LayoutContainer>
          ),
        };
      }
      return render404;
    }

    return redirectToLogin(context);
  }
};
