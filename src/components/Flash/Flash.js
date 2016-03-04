import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Flash.scss';

class Flash extends Component {

  static propTypes = {
    expireFlash: PropTypes.func.isRequired,
    message: PropTypes.string.isRequired,
    type: PropTypes.string.isRequired
  };

  componentDidMount() {
    setTimeout(this.props.expireFlash, 5000);
  }

  render() {
    return (
      <div className={`${s.root} ${s[this.props.type]}`}>{this.props.message}</div>
    );
  }

}

export default withStyles(Flash, s);
