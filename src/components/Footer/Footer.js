/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import PropTypes from 'prop-types';
import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import s from './Footer.scss';

const Footer = ({ host }) => (
  <div className={s.root}>
    <div className={s.container}>
      <a className={s.link} href={`//${host}/about`}>
        About / Privacy
      </a>
      <span className={s.spacer} />
      <span className={s.text}>
        ©
        <a
          className={s.link}
          href="https://labzero.com"
          target="_blank"
          rel="noopener noreferrer"
        >
          Lab Zero
        </a>
      </span>
    </div>
  </div>
);

Footer.propTypes = {
  host: PropTypes.string.isRequired,
};

export default withStyles(s)(Footer);
