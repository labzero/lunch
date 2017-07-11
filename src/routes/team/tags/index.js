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
import hasRole from '../../../helpers/hasRole';
import renderIfHasName from '../../helpers/renderIfHasName';
import render404 from '../../helpers/render404';
import TagsContainer from './TagsContainer';

const title = 'Tags';

export default (context) => {
  const state = context.store.getState();
  const user = state.user;
  const team = state.team;

  return renderIfHasName(context, () => {
    if (team.id && hasRole(user, team)) {
      return {
        title,
        chunks: ['tags'],
        component: (
          <LayoutContainer path={context.url}>
            <TagsContainer title={title} />
          </LayoutContainer>
        ),
      };
    }
    return render404;
  });
};
