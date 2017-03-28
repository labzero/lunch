/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

export default {

  path: '/teams',

  action(context) {
    const state = context.store.getState();
    const host = state.host;

    return {
      redirect: `//${host}/teams`,
      status: 301
    };
  }
};
