import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantVoteButton.scss';

const RestaurantVoteButton = ({ handleClick }) => (
  <button onClick={handleClick}>+1</button>
);

RestaurantVoteButton.propTypes = {
  handleClick: PropTypes.func.isRequired
};

export default withStyles(RestaurantVoteButton, s);
