/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import loadComponent from '../../../helpers/loadComponent';
import LayoutContainer from '../../../components/Layout/LayoutContainer';

const title = 'About / Privacy';

export default {

  path: '/about',

  action(context) {
    return loadComponent(
      () => require.ensure([], require => require('./About').default, 'about')
    ).then(About => ({
      title,
      chunk: 'about',
      component: (
        <LayoutContainer path={context.url}>
          <About />
        </LayoutContainer>
      ),
    }));
  },

};
