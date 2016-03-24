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
import s from './Footer.scss';

const Footer = ({ manageTags }) => (
  <div className={s.root}>
    <div className={s.container}>
      <button className={`${s.link} ${s.text}`} onClick={manageTags}>Manage Tags</button>
      <span className={s.spacer}></span>
      <span className={s.text}>© Lab Zero</span>
    </div>
  </div>
);

Footer.propTypes = {
  manageTags: PropTypes.func.isRequired
};

export default withStyles(Footer, s);
