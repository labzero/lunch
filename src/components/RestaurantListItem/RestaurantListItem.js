import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantListItem.scss';

class RestaurantListItem extends Component {

  static propTypes = {
    name: PropTypes.string.isRequired
  };

  render() {
    return (
      <li>{this.props.name}</li>
    );
  }

}

export default withStyles(RestaurantListItem, s);
