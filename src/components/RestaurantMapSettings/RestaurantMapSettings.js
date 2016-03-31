import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMapSettings.scss';

const RestaurantMapSettings = ({ showUnvoted, setShowUnvoted }) => (
  <div className={`checkbox ${s.root}`}>
    <label>
      <input type="checkbox" checked={showUnvoted} onChange={setShowUnvoted} />
      Show Unvoted
    </label>
  </div>
);

RestaurantMapSettings.propTypes = {
  showUnvoted: PropTypes.bool.isRequired,
  setShowUnvoted: PropTypes.func.isRequired
};

export default withStyles(RestaurantMapSettings, s);
