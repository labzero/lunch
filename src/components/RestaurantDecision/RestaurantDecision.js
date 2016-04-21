import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantDecision.scss';

const RestaurantDecision = ({ decided, loggedIn, handleClick }) =>
  loggedIn || decided ?
    (
      <button
        onClick={handleClick}
        className={`${s.root} ${loggedIn ? '' : s.loggedOut} ${decided ? s.decided : ''}`}
      >
        ✔
      </button>
    )
    :
    false;

RestaurantDecision.propTypes = {
  decided: PropTypes.bool.isRequired,
  handleClick: PropTypes.func.isRequired,
  loggedIn: PropTypes.bool.isRequired
};

export default withStyles(RestaurantDecision, s);
