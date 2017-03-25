/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import emptyFunction from 'fbjs/lib/emptyFunction';
import HeaderContainer from '../Header/HeaderContainer';
import FooterContainer from '../Footer/FooterContainer';
import NotificationListContainer from '../NotificationList/NotificationListContainer';
import ModalSectionContainer from '../ModalSection/ModalSectionContainer';
import s from './Layout.scss';
// eslint-disable-next-line css-modules/no-unused-class
import globalCss from '../../styles/globalCss.scss';

class Layout extends Component {

  static propTypes = {
    children: PropTypes.element.isRequired,
    shouldScrollToTop: PropTypes.bool.isRequired,
    scrolledToTop: PropTypes.func.isRequired,
    teamSlug: PropTypes.string // temp
  };

  static defaultProps = {
    teamSlug: ''
  };

  static contextTypes = {
    insertCss: PropTypes.func,
  };

  static childContextTypes = {
    insertCss: PropTypes.func.isRequired,
  };

  getChildContext() {
    const context = this.context;
    return {
      insertCss: context.insertCss || emptyFunction,
    };
  }

  componentWillMount() {
    this.removeCss = this.context.insertCss(s, globalCss);
  }

  componentDidUpdate() {
    if (this.props.shouldScrollToTop) {
      if (canUseDOM) {
        // defeat bootstrap menu close by using timeout
        setTimeout(() => {
          window.scrollTo(0, 0);
        });
      }
      this.props.scrolledToTop();
    }
  }

  componentWillUnmount() {
    this.removeCss();
  }

  render() {
    const { teamSlug } = this.props;

    return (
      <div>
        <HeaderContainer />
        {this.props.children}
        <FooterContainer teamSlug={teamSlug} /* temporary */ />
        <NotificationListContainer />
        <ModalSectionContainer />
      </div>
    );
  }

}

export default Layout;
