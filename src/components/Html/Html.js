/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component, PropTypes } from 'react';
import { analytics } from '../../config';
import serialize from 'serialize-javascript';

// https://analytics.google.com/
const trackingCode =
  'window.ga=function(){ga.q.push(arguments)};ga.q=[];ga.l=+new Date;' +
  `ga('create','${analytics.google.trackingId}','auto');`;

const generateInitialState = (initialState) =>
  `window.__INITIAL_STATE__ = ${serialize(initialState)}`;

class Html extends Component {

  static propTypes = {
    title: PropTypes.string,
    description: PropTypes.string,
    css: PropTypes.string,
    body: PropTypes.string.isRequired,
    entry: PropTypes.string.isRequired,
    initialState: PropTypes.object.isRequired
  };

  static defaultProps = {
    title: '',
    description: '',
    initialState: {}
  };

  render() {
    return (
      <html className="no-js" lang="">
      <head>
        <meta charSet="utf-8" />
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
        <title>{this.props.title}</title>
        <meta name="description" content={this.props.description} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="apple-touch-icon" href="apple-touch-icon.png" />
        <link href='https://fonts.googleapis.com/css?family=Sniglet:800' rel='stylesheet' type='text/css' />
        <style id="css" dangerouslySetInnerHTML={{ __html: this.props.css }} />
      </head>
      <body>
        <div id="app" dangerouslySetInnerHTML={{ __html: this.props.body }} ></div>
        <script dangerouslySetInnerHTML={{ __html: generateInitialState(this.props.initialState) }}></script>
        <script dangerouslySetInnerHTML={{ __html: trackingCode }} ></script>
        <script src="https://maps.googleapis.com/maps/api/js?libraries=places"></script>
        <script src={this.props.entry}></script>
        <script src="https://www.google-analytics.com/analytics.js" async defer ></script>
      </body>
      </html>
    );
  }

}

export default Html;
