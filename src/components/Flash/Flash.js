import PropTypes from "prop-types";
import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
// eslint-disable-next-line css-modules/no-unused-class
import s from "./Flash.scss";

class Flash extends Component {
  static propTypes = {
    expireFlash: PropTypes.func.isRequired,
    message: PropTypes.string.isRequired,
    type: PropTypes.string.isRequired,
  };

  componentDidMount() {
    setTimeout(this.props.expireFlash, 5000);
  }

  render() {
    return (
      <div className={`${s.root} ${s[this.props.type]}`}>
        {this.props.message}
      </div>
    );
  }
}

export default withStyles(s)(Flash);
