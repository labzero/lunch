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
import LayoutContainer from '../../../../containers/LayoutContainer';

const title = 'Admin';

export default {

  path: '/admin',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;
    const team = state.team;

    if (user.id && hasRole(user, team, 'admin')) {
      const AdminContainer = await require.ensure([], require => require('./AdminContainer').default, 'admin');

      return {
        title,
        chunk: 'admin',
        component: <LayoutContainer><AdminContainer title={title} /></LayoutContainer>,
      };
    }

    let stringifiedQuery = queryString.stringify(context.query);
    if (stringifiedQuery) {
      stringifiedQuery = `%3F${stringifiedQuery}`;
    }

    return { redirect: `/login?next=${context.path}${stringifiedQuery}` };
  },

};
