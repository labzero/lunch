import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
// eslint-disable-next-line css-modules/no-unused-class
import s from "./Flash.scss";

interface FlashProps {
  expireFlash: () => void;
  message: string;
  type: keyof typeof s;
}

class Flash extends Component<FlashProps> {
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
