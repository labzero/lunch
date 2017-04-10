/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import hasRole from '../../../helpers/hasRole';
import redirectToLogin from '../../helpers/redirectToLogin';
import render404 from '../../helpers/render404';

export default {

  path: '/teams',

  action(context) {
    const state = context.store.getState();
    const host = state.host;
    const team = state.team;
    const user = state.user;

    if (user.id) {
      if (team.id && hasRole(user, team)) {
        return {
          redirect: `//${host}/teams`,
          status: 301
        };
      }
      return render404;
    }

    return redirectToLogin(context);
  }
};
