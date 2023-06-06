/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";
import PropTypes from "prop-types";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import emptyFunction from "fbjs/lib/emptyFunction";
import HeaderContainer from "../Header/HeaderContainer";
import FooterContainer from "../Footer/FooterContainer";
import NotificationListContainer from "../NotificationList/NotificationListContainer";
import ConfirmModalContainer from "../ConfirmModal/ConfirmModalContainer";
import s from "./Layout.scss";
// eslint-disable-next-line css-modules/no-unused-class, no-unused-vars
import globalCss from "../../styles/globalCss.scss";
import { InsertCSS } from "isomorphic-style-loader/StyleContext";

export interface LayoutProps {
  children: ReactNode;
  isHome?: boolean;
  path: string;
  shouldScrollToTop: boolean;
  confirmShown: boolean;
  scrolledToTop: () => void;
}

interface LayoutContext {
  insertCss: InsertCSS;
}

class Layout extends Component<LayoutProps> {
  declare context: LayoutContext;

  static defaultProps = {
    isHome: false,
  };

  static contextTypes = {
    insertCss: PropTypes.func,
  };

  static childContextTypes = {
    insertCss: PropTypes.func.isRequired,
  };

  constructor(props: LayoutProps, context: LayoutContext) {
    super(props);
    context.insertCss(s, globalCss);
  }

  getChildContext() {
    const context = this.context;
    return {
      insertCss: context.insertCss || emptyFunction,
    };
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

  render() {
    const { confirmShown, isHome, path } = this.props;

    return (
      <div className={s.root}>
        <HeaderContainer path={path} />
        {this.props.children}
        {!isHome && <FooterContainer />}
        <NotificationListContainer />
        {confirmShown && <ConfirmModalContainer />}
      </div>
    );
  }
}

export default Layout;
