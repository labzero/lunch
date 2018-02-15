import PropTypes from 'prop-types';
/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import Grid from 'react-bootstrap/lib/Grid';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './NotFound.scss';

class NotFound extends React.Component {
  static propTypes = {
    title: PropTypes.string.isRequired,
  };

  render() {
    return (
      <div className={s.root}>
        <Grid>
          <h2>{this.props.title}</h2>
          <p>Sorry, the page you were trying to view does not exist.</p>
        </Grid>
      </div>
    );
  }
}

export default withStyles(s)(NotFound);
