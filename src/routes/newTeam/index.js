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
import LayoutContainer from '../../components/Layout/LayoutContainer';
import NewTeamContainer from './NewTeamContainer';

const title = 'New Team';

export default {

  path: '/new-team',

  async action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      return {
        title,
        chunk: 'admin',
        component: <LayoutContainer><NewTeamContainer title={title} /></LayoutContainer>,
      };
    }

    let stringifiedQuery = queryString.stringify(context.query);
    if (stringifiedQuery) {
      stringifiedQuery = `%3F${stringifiedQuery}`;
    }

    return { redirect: `/login?next=${context.path}${stringifiedQuery}` };
  },

};
