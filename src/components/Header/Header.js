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
import s from './Header.scss';
import { IndexLink } from 'react-router';
import LoginContainer from '../../containers/LoginContainer';
import FlashContainer from '../../containers/FlashContainer';

const Header = ({ flashes }) => {
  const flashContainers = flashes.map(
    (flash, i) => <FlashContainer message={flash.message} type={flash.type} id={i} key={`flash_${i}`} />
  );

  return (
    <div className={s.root}>
      <div className={s.flashes}>
        {flashContainers}
      </div>
      <LoginContainer />
      <div className={s.container}>
        <div className={s.banner}>
          <h1 className={s.bannerTitle}>
            <IndexLink to="/">Lunch</IndexLink>
          </h1>
        </div>
      </div>
    </div>
  );
};

Header.propTypes = {
  flashes: PropTypes.array.isRequired
};

export default withStyles(Header, s);
