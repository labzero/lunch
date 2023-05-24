/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import { Flash } from "../../interfaces";
import HeaderLoginContainer from "../HeaderLogin/HeaderLoginContainer";
import FlashContainer from "../Flash/FlashContainer";
import MenuContainer from "../Menu/MenuContainer";
import Link from "../Link/Link";
import lunch from "./lunch.png";
import s from "./Header.scss";

export interface HeaderProps {
  flashes: Flash[];
  loggedIn: boolean;
  path: string;
}

interface HeaderState {
  menuOpen: boolean;
  prevPath: string | null;
}

class Header extends Component<HeaderProps, HeaderState> {
  static getDerivedStateFromProps(nextProps: HeaderProps, state: HeaderState) {
    if (nextProps.path !== state.prevPath) {
      return {
        menuOpen: false,
        prevPath: nextProps.path,
      };
    }
    return null;
  }

  constructor(props: HeaderProps) {
    super(props);

    this.state = {
      menuOpen: false,
      // eslint-disable-next-line react/no-unused-state
      prevPath: null,
    };
  }

  flashContainers = () => {
    const { flashes } = this.props;

    return flashes.map((flash) => <FlashContainer key={flash.id} {...flash} />);
  };

  closeMenu = () => {
    this.setState({
      menuOpen: false,
    });
  };

  toggleMenu = () => {
    this.setState((prevState) => ({
      menuOpen: !prevState.menuOpen,
    }));
  };

  render() {
    const { loggedIn } = this.props;
    const { menuOpen } = this.state;
    return (
      <div className={`${s.root} ${loggedIn ? s.loggedIn : ""}`} id="header">
        <div className={s.backgroundOverflow}>
          <div className={s.background} />
        </div>
        <div className={s.flashes}>{this.flashContainers()}</div>
        <div className={s.container}>
          <div className={s.banner}>
            <h1 className={s.bannerTitle}>
              <Link to="/">
                <img src={lunch} alt="Lunch" />
              </Link>
            </h1>
          </div>
        </div>
        {loggedIn ? (
          <div>
            <button
              className={s.hamburger}
              onClick={this.toggleMenu}
              type="button"
            >
              <span>Menu</span>
            </button>
            {menuOpen && (
              <button
                aria-label="Close"
                className={s.menuBackground}
                onClick={this.closeMenu}
                type="button"
              />
            )}
            <MenuContainer open={menuOpen} closeMenu={this.closeMenu} />
          </div>
        ) : (
          <HeaderLoginContainer />
        )}
      </div>
    );
  }
}

export default withStyles(s)(Header);
