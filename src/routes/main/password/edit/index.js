/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import LayoutContainer from '../../../../components/Layout/LayoutContainer';
import renderIfLoggedOut from '../../../helpers/renderIfLoggedOut';
import Edit from './Edit';

export default {

  path: '/edit',

  action(context) {
    const state = context.store.getState();

    const token = context.query.token;

    return renderIfLoggedOut(state, () => {
      if (!token) {
        return {
          redirect: '/password/new'
        };
      }

      return {
        component: (
          <LayoutContainer path={context.url}>
            <Edit token={token} />
          </LayoutContainer>
        ),
      };
    });
  },
};
