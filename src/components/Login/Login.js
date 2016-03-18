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
import s from './Login.scss';

const Header = ({ user }) => {
  let content;
  if (user.id === undefined) {
    content = (<div className={s.flexContainer}><a href="/login">Log In</a></div>);
  } else {
    content = (
      <div className={s.flexContainer}>
        <span>{user.name}</span>
        <a className={s.logOut} href="/logout">Log Out</a>
      </div>
    );
  }

  return (
    <div className={s.root}>
      {content}
    </div>
  );
};

Header.propTypes = {
  user: PropTypes.object.isRequired
};

export default withStyles(Header, s);
