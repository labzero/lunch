import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantDeleteButton.scss';

const RestaurantDeleteButton = ({ handleClick }) => (
  <button className={s.root} onClick={handleClick}>Delete</button>
);

RestaurantDeleteButton.propTypes = {
  handleClick: PropTypes.func.isRequired
};

export default withStyles(RestaurantDeleteButton, s);
