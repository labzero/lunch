import React, { Component, PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantListItem.scss';

class RestaurantListItem extends Component {

  static propTypes = {
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    address: PropTypes.string.isRequired,
    user: PropTypes.object.isRequired
  };

  render() {
    let deleteButton = null;
    if (typeof this.props.user.id === 'number') {
      // voteButton = <RestaurantVoteButtonContainer id={this.props.id} />;
      deleteButton = <RestaurantDeleteButtonContainer id={this.props.id} />;
    }

    return (
      <li>
        <h2>{this.props.name}</h2>
        {this.props.address}
        {deleteButton}
      </li>
    );
  }
}

export default withStyles(RestaurantListItem, s);
