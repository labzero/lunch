/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Footer.scss';

const Footer = () => (
  <div className={s.root}>
    <div className={s.container}>
      <span className={s.text}>© Lab Zero</span>
    </div>
  </div>
);

export default withStyles(Footer, s);
