import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantTag.scss';

const RestaurantTag = ({ tag, removeTag }) => (
  <div className={s.root}>
    {tag.name}
    <button className={s.delete} onClick={removeTag}>&times;</button>
  </div>
);

RestaurantTag.propTypes = {
  tag: PropTypes.object.isRequired
};

export default withStyles(RestaurantTag, s);
