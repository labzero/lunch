/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import s from './HeaderLogin.scss';

const HeaderLogin = ({ user }) => {
  let content = <div />;
  if (user.id === undefined) {
    content = (
      <div className={s.root}>
        <Button bsSize="small" bsStyle="primary" href="/login">
          Log In
        </Button>
      </div>
    );
  }

  return content;
};

HeaderLogin.propTypes = {
  user: PropTypes.object.isRequired
};

export default withStyles(s)(HeaderLogin);
