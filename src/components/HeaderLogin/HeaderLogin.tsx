/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import PropTypes from "prop-types";
import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import { User } from "../../interfaces";
import s from "./HeaderLogin.scss";

interface HeaderLoginProps {
  user: User;
}

const HeaderLogin = ({ user }: HeaderLoginProps) => {
  let content = <div />;
  if (user === null) {
    content = (
      <div className={s.root}>
        <Button variant="primary" href="/login">
          Log in
        </Button>
      </div>
    );
  }

  return content;
};

HeaderLogin.propTypes = {
  user: PropTypes.object,
};

HeaderLogin.defaultProps = {
  user: null,
};

export default withStyles(s)(HeaderLogin);
