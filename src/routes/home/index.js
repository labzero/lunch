/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import HomeContainer from './HomeContainer';
import LayoutContainer from '../../containers/LayoutContainer';

export default {

  path: '/',

  action() {
    return {
      title: 'Lunch',
      component: <LayoutContainer><HomeContainer /></LayoutContainer>,
    };
  },
};
