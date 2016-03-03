import React, { Component, PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantListItem.scss';

class RestaurantListItem extends Component {

  static propTypes = {
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired
  };

  render() {
    return (
      <li>
        {this.props.name}
        <RestaurantDeleteButtonContainer id={this.props.id} />
      </li>
    );
  }
}

export default withStyles(RestaurantListItem, s);
