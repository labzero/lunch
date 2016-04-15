import React, { PropTypes } from 'react';

const TooltipUser = ({ vote, user }) => {
  if (user !== undefined) {
    return <div key={`restaurantVote_${vote.id}`}>{user.name}</div>;
  }
  return null;
};

TooltipUser.propTypes = {
  vote: PropTypes.object.isRequired,
  user: PropTypes.object.isRequired
};

export default TooltipUser;
