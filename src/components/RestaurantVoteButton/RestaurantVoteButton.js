import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantVoteButton.scss';

const RestaurantVoteButton = ({ votes, user, handleClick }) => {
  let downVote = false;
  if (votes.some(vote => vote.user_id === user.id)) {
    downVote = true;
  }

  return (
    <button onClick={handleClick}>{downVote ? '-1' : '+1'}</button>
  );
};

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
