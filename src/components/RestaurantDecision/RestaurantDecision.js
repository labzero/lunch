import React, { PropTypes } from 'react';
import OverlayTrigger from 'react-bootstrap/lib/OverlayTrigger';
import Tooltip from 'react-bootstrap/lib/Tooltip';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantDecision.scss';

// TODO return null when upgrading to React 15
const RestaurantDecision = ({ id, votes, decided, loggedIn, handleClick }) => {
  const tooltip = (
    <Tooltip id={`restaurantDecisionTooltip_${id}`}>We went here{decided ? '!' : '?'}</Tooltip>
  );

  return ((loggedIn && votes.length > 0) || decided) &&
    (
    <OverlayTrigger placement="top" overlay={tooltip}>
      <button
        onClick={handleClick}
        className={`${s.root} ${loggedIn ? '' : s.loggedOut} ${decided ? s.decided : ''}`}
      >
        ✔
      </button>
    </OverlayTrigger>
    );
};

RestaurantDecision.propTypes = {
  id: PropTypes.number.isRequired,
  votes: PropTypes.array.isRequired,
  decided: PropTypes.bool.isRequired,
  handleClick: PropTypes.func.isRequired,
  loggedIn: PropTypes.bool.isRequired
};

export default withStyles(s)(RestaurantDecision);
