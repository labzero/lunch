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
import LayoutContainer from '../../containers/LayoutContainer';

const title = 'Admin';

const hasRole = (user, team, role) => {
  if (!role || user.superuser) {
    return true;
  }
  const teamRole = user.roles.find(userRole => userRole.team_id === userRole.id);
  if (!teamRole) {
    return false;
  }
  switch (role) {
    case 'admin':
      return teamRole.type === 'admin' || teamRole.type === 'owner';
    case 'owner':
      return teamRole.type === 'owner';
    default:
      return false;
  }
};

export default {

  path: '/admin',

  async action(context) {
    console.log(context);

    const state = context.store.getState();
    const user = state.user;
    const team = state.team;

    if (user.id && hasRole(user, team, 'admin')) {
      const Admin = await require.ensure([], require => require('./Admin').default, 'admin');

      return {
        title,
        chunk: 'admin',
        component: <LayoutContainer><Admin title={title} /></LayoutContainer>,
      };
    }

    let stringifiedQuery = queryString.stringify(context.query);
    if (stringifiedQuery) {
      stringifiedQuery = `%3F${stringifiedQuery}`;
    }

    return { redirect: `/login?next=${context.path}${stringifiedQuery}` };
  },

};
