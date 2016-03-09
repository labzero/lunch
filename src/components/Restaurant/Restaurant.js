import React, { Component, PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Restaurant.scss';

class Restaurant extends Component {

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
      voteButton = <RestaurantVoteButtonContainer id={this.props.id} votes={this.props.votes} />;
      deleteButton = (
        <div className={s.deleteButtonContainer}>
          <RestaurantDeleteButtonContainer id={this.props.id} />
        </div>
      );
    }

    return (
      <div className={s.root}>
        <div className={s.header}>
          <h2 className={s.heading}>{this.props.name}</h2>
          <div className={s.voteButtonContainer}>
            {this.props.votes.length} {this.props.votes.length === 1 ? 'vote' : 'votes'}
            &nbsp;
            {voteButton}
          </div>
        </div>
        {this.props.address}
        {deleteButton}
      </div>
    );
  }
}

export default withStyles(Restaurant, s);
