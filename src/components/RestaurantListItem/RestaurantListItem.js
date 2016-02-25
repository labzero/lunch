import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantListItem.scss';

class RestaurantListItem extends Component {

  static contextTypes = {
    // onSetTitle: PropTypes.func.isRequired
  };

  componentWillMount() {
    // this.context.onSetTitle(title);
  }

  render() {
    return (
      <div>Hello</div>
    );
  }

}

export default withStyles(RestaurantListItem, s);
