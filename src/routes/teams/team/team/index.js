/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import queryString from 'query-string';
import hasRole from '../../../../helpers/hasRole';
import LayoutContainer from '../../../../components/Layout/LayoutContainer';
import { getTeamBySlug } from '../../../../selectors/teams';

const title = 'Team';

export default {

  path: '/team',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = getTeamBySlug(state, context.params.slug);

    if (user.id && hasRole(user, team, 'member')) {
      const TeamContainer = await require.ensure([], require => require('./TeamContainer').default, 'team');

      return {
        title,
        chunk: 'admin',
        component: (
          <LayoutContainer>
            <TeamContainer title={title} teamSlug={context.params.slug} />
          </LayoutContainer>
        ),
      };
    }

    let stringifiedQuery = queryString.stringify(context.query);
    if (stringifiedQuery) {
      stringifiedQuery = `%3F${stringifiedQuery}`;
    }

    return { redirect: `/login?next=${context.path}${stringifiedQuery}` };
  },

};
