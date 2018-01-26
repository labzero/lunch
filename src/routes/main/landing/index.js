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
import renderIfLoggedOut from '../../helpers/renderIfLoggedOut';
import Landing from './Landing';

export default (context) => {
  const state = context.store.getState();

  return renderIfLoggedOut(state, () => ({
    chunks: ['landing'],
    component: (
      <LayoutContainer path={context.pathname}>
        <Landing />
      </LayoutContainer>
    ),
  }));
};
