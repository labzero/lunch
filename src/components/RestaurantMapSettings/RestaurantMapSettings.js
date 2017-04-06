import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMapSettings.scss';

const RestaurantMapSettings = ({ showUnvoted, showPOIs, setShowPOIs, setShowUnvoted }) => (
  <div className={`checkbox ${s.root}`}>
    <label htmlFor="show-unvoted">
      <input id="show-unvoted" type="checkbox" checked={showUnvoted} onChange={setShowUnvoted} />
      Show Unvoted
    </label>
    <label htmlFor="show-pois">
      <input id="show-pois" type="checkbox" checked={showPOIs} onChange={setShowPOIs} />
      Show Points of Interest
    </label>
  </div>
);

RestaurantMapSettings.propTypes = {
  showPOIs: PropTypes.bool.isRequired,
  setShowPOIs: PropTypes.func.isRequired,
  showUnvoted: PropTypes.bool.isRequired,
  setShowUnvoted: PropTypes.func.isRequired
};

export default withStyles(s)(RestaurantMapSettings);
