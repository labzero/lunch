import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantVoteButton.scss';

class RestaurantVoteButton extends Component {
  render() {
    let downVote = false;
    if (this.props.votes.some(vote => vote.user_id === this.props.user.id)) {
      downVote = true;
    }

    return (
      <button onClick={this.props.handleClick}>{downVote ? '-1' : '+1'}</button>
    );
  }
}

RestaurantVoteButton.propTypes = {
  handleClick: PropTypes.func.isRequired,
  user: PropTypes.shape({
    id: PropTypes.number.isRequired
  }).isRequired,
  votes: PropTypes.arrayOf(PropTypes.shape({
    user_id: PropTypes.number.isRequired
  })).isRequired
};

export default withStyles(RestaurantVoteButton, s);
