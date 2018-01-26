/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import LayoutContainer from '../../../components/Layout/LayoutContainer';
import redirectToLogin from '../../helpers/redirectToLogin';
import WelcomeContainer from './WelcomeContainer';

const title = 'Welcome!';

export default (context) => {
  const state = context.store.getState();
  const user = state.user;

  if (user.id) {
    return {
      title,
      chunks: ['welcome'],
      component: (
        <LayoutContainer path={context.pathname}>
          <WelcomeContainer next={context.query.next} team={context.query.team} />
        </LayoutContainer>
      )
    };
  }

  return redirectToLogin(context);
};
