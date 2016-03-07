import React, { Component, PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantListItem.scss';

class RestaurantListItem extends Component {

  static propTypes = {
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    address: PropTypes.string.isRequired,
    user: PropTypes.object.isRequired,
    votes: PropTypes.array.isRequired
  };

  render() {
    let deleteButton = null;
    let voteButton = null;
    if (typeof this.props.user.id === 'number') {
      voteButton = (
        <div className={s.voteButtonContainer}>
          <RestaurantVoteButtonContainer id={this.props.id} votes={this.props.votes} />
        </div>
      );
      deleteButton = <RestaurantDeleteButtonContainer id={this.props.id} />;
    }

    return (
      <li className={s.root}>
        <div className={s.header}>
          <h2 className={s.heading}>{this.props.name}</h2>
          {voteButton}
        </div>
        {this.props.address}
        {deleteButton}
      </li>
    );
  }
}

export default withStyles(RestaurantListItem, s);
