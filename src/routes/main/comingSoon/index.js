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
import ComingSoon from './ComingSoon';

const title = 'New Team';

export default {

  path: '/coming-soon',

  async action(context) {
    return {
      title,
      // chunk: 'admin',
      component: (
        <LayoutContainer path={context.url}>
          <ComingSoon />
        </LayoutContainer>
      ),
    };
  },

};
