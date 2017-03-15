/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import queryString from 'query-string';
import { getTeamEntities } from '../../selectors/teams';

export default {

  path: '/',

  action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      if (user.roles.length === 1) {
        const team = getTeamEntities(state)[0];
        return {
          redirect: `/teams/${team.slug}`
        };
      }
      return {
        redirect: '/teams'
      };
    }

    let stringifiedQuery = queryString.stringify(context.query);
    if (stringifiedQuery) {
      stringifiedQuery = `%3F${stringifiedQuery}`;
    }

    return { redirect: `/login?next=${context.path}${stringifiedQuery}` };
  },
};
