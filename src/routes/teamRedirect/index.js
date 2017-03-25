/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import { getTeams } from '../../selectors/teams';
import redirectToLogin from '../helpers/redirectToLogin';

export default {

  path: '/',

  action(context) {
    const state = context.store.getState();
    const user = state.user;

    if (user.id) {
      if (user.roles.length === 1) {
        const team = getTeams(state)[0];
        return {
          redirect: `/teams/${team.slug}`
        };
      }
      return {
        redirect: '/teams'
      };
    }

    return redirectToLogin(context);
  },
};
