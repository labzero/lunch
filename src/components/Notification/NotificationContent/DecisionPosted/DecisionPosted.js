import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const DecisionPosted = ({
  decision, loggedIn, user, restaurantName, showMapAndInfoWindow
}) => {
  const restaurantEl = (
    <button className={s.clickable} onClick={showMapAndInfoWindow} type="button">
      {restaurantName}
    </button>
  );
  if (loggedIn) {
    if (moment().subtract(12, 'hours').isAfter(decision.created_at)) {
      return (
        <span>
          <b>{user}</b>
          {' '}
marked
          {restaurantEl}
          {' '}
as a past decision.
        </span>
      );
    }
    return (
      <span>
        <b>{user}</b>
        {' '}
marked
        {restaurantEl}
        {' '}
as today&rsquo;s decision.
      </span>
    );
  }
  return (
    <span>
      {restaurantEl}
      {' '}
was decided upon.
    </span>
  );
};

DecisionPosted.propTypes = {
  decision: PropTypes.object.isRequired,
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

DecisionPosted.defaultProps = {
  user: ''
};

export default withStyles(s)(DecisionPosted);
