import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantListItem from '../RestaurantListItem';

class RestaurantList extends Component {

  static contextTypes = {
    // onSetTitle: PropTypes.func.isRequired
  };

  componentWillMount() {
    // this.context.onSetTitle(title);
  }

  render() {
    return (
      <RestaurantListItem />
    );
  }

}

export default withStyles(RestaurantList, s);
