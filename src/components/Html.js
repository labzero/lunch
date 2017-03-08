/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable react/no-danger */

import React, { Component, PropTypes } from 'react';
import { analytics } from '../config';

class Html extends Component {
  static propTypes = {
    apikey: PropTypes.string,
    title: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    initialState: PropTypes.string,
    root: PropTypes.string,
    styles: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string.isRequired,
      cssText: PropTypes.string.isRequired,
    }).isRequired),
    scripts: PropTypes.arrayOf(PropTypes.string.isRequired),
    children: PropTypes.string.isRequired,
  };

  static defaultProps = {
    apikey: '',
    initialState: '',
    styles: [],
    scripts: [],
    root: ''
  };

  render() {
    const {
      apikey,
      initialState,
      title,
      description,
      root,
      styles,
      scripts,
      children
    } = this.props;

    return (
      <html className="no-js" lang="en">
        <head>
          <meta charSet="utf-8" />
          <meta httpEquiv="x-ua-compatible" content="ie=edge" />
          <title>{title}</title>
          <meta name="description" content={description} />
          <meta property="og:title" content={title} />
          <meta property="og:description" content={description} />
          <meta property="og:image" content={`${root}/tile.png`} />
          <meta property="og:site_name" content="Lab Zero" />
          <meta property="og:url" content={root} />
          <meta property="og:type" content="website" />
          <meta property="twitter:card" content="summary" />
          <meta property="twitter:site" content="labzero" />
          <meta property="twitter:image" content={`${root}/tile.png`} />
          <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
          <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Nunito:400,900" />
          <link rel="apple-touch-icon" href="apple-touch-icon.png" />
          {styles.map(style =>
            <style
              key={style.id}
              id={style.id}
              // eslint-disable-next-line react/no-danger
              dangerouslySetInnerHTML={{ __html: style.cssText }}
            />,
          )}
        </head>
        <body>
          <div id="app" dangerouslySetInnerHTML={{ __html: children }} />
          {initialState && <script
            dangerouslySetInnerHTML={{ __html: `window.__INITIAL_STATE__ = ${initialState};` }}
          />}
          {analytics.google.trackingId &&
            <script
              dangerouslySetInnerHTML={{ __html:
              'window.ga=function(){ga.q.push(arguments)};ga.q=[];ga.l=+new Date;' +
              `ga('create','${analytics.google.trackingId}','auto');ga('send','pageview')` }}
            />
          }
          {analytics.google.trackingId &&
            <script src="https://www.google-analytics.com/analytics.js" async defer />
          }
          {apikey && <script src={`https://maps.googleapis.com/maps/api/js?key=${apikey}&libraries=places`} />}
          {scripts.map(script => <script key={script} src={script} />)}
        </body>
      </html>
    );
  }
}

export default Html;
