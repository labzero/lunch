import PropTypes from 'prop-types';
import React from 'react';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Tooltip from 'react-bootstrap/Tooltip';
import withStyles from 'isomorphic-style-loader/withStyles';
import s from './RestaurantDecision.scss';

// TODO return null when upgrading to React 15
const RestaurantDecision = ({
  id, votes, decided, loggedIn, handleClick
}) => {
  const tooltip = (
    <Tooltip id={`restaurantDecisionTooltip_${id}`}>
      We ate here
      {decided ? '!' : '?'}
    </Tooltip>
  );

  return (
    ((loggedIn && votes.length > 0) || decided) && (
      <OverlayTrigger placement="top" overlay={tooltip}>
        <span
          className={`${s.root} ${loggedIn ? '' : s.loggedOut} ${
            decided ? s.decided : ''
          }`}
          onClick={handleClick}
          onKeyPress={handleClick}
          role="button"
          tabIndex={0}
        >
          ✔
        </span>
      </OverlayTrigger>
    )
  );
};

RestaurantDecision.propTypes = {
  id: PropTypes.number.isRequired,
  votes: PropTypes.array.isRequired,
  decided: PropTypes.bool.isRequired,
  handleClick: PropTypes.func.isRequired,
  loggedIn: PropTypes.bool.isRequired,
};

export default withStyles(s)(RestaurantDecision);
