/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import LayoutContainer from '../../components/Layout/LayoutContainer';
import NotFound from './NotFound';

const title = 'Page Not Found';

export default {

  path: '*',

  action() {
    return {
      title,
      component: <LayoutContainer><NotFound title={title} /></LayoutContainer>,
      status: 404,
    };
  },

};
