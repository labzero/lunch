/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component, MouseEvent, ReactNode } from "react";
import history from "../../history";

function isLeftClickEvent(event: MouseEvent) {
  return event.button === 0;
}

function isModifiedEvent(event: MouseEvent) {
  return !!(event.metaKey || event.altKey || event.ctrlKey || event.shiftKey);
}

interface LinkProps {
  to: string;
  children: ReactNode;
  onClick?: (event: MouseEvent) => void;
}

class Link extends Component<LinkProps> {
  static defaultProps = {
    onClick: null,
  };

  handleClick = (event: MouseEvent) => {
    if (this.props.onClick) {
      this.props.onClick(event);
    }

    if (isModifiedEvent(event) || !isLeftClickEvent(event)) {
      return;
    }

    if (event.defaultPrevented === true) {
      return;
    }

    event.preventDefault();

    if (window.swUpdate) {
      window.location.href = this.props.to;
    } else {
      history!.push(this.props.to);
    }
  };

  render() {
    const { to, children, ...props } = this.props;
    return (
      <a href={to} {...props} onClick={this.handleClick}>
        {children}
      </a>
    );
  }
}

export default Link;
