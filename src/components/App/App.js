/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component, PropTypes } from 'react';
import s from './App.scss';
import globalCss from '../../globalCss.scss';
import HeaderContainer from '../../containers/HeaderContainer';
import Footer from '../Footer';
import DeleteRestaurantModalContainer from '../../containers/DeleteRestaurantModalContainer';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import { host } from '../../config';

class App extends Component {

  static propTypes = {
    children: PropTypes.element.isRequired,
    messageReceived: PropTypes.func.isRequired,
    modals: PropTypes.object.isRequired,
    error: PropTypes.object,
  };

  static contextTypes = {
    insertCss: PropTypes.func,
  };

  componentWillMount() {
    this.removeAppCss = this.context.insertCss(s);
    this.removeGlobalCss = this.context.insertCss(globalCss);
    if (canUseDOM) {
      this.socket = new window.WebSocket(`ws://${window.location.host}`);
      this.socket.onmessage = this.props.messageReceived;
    }
  }

  componentWillUnmount() {
    this.removeAppCss();
    this.removeGlobalCss();
  }

  render() {
    const modals = [];
    if (this.props.modals.deleteRestaurant !== undefined) {
      modals.push(<DeleteRestaurantModalContainer key={modals.length} />);
    }

    return !this.props.error ? (
      <div>
        <HeaderContainer />
        {this.props.children}
        <Footer />
        {modals}
      </div>
    ) : this.props.children;
  }

}

export default App;
