import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantTag.scss';

const RestaurantTag = ({ tag, removeTag, user }) => {
  let button = null;
  if (user.id !== undefined) {
    button = <button className={s.delete} onClick={removeTag}>&times;</button>;
  }

  return (
    <div className={s.root}>
      {tag.name}
      {button}
    </div>
  );
};

RestaurantTag.propTypes = {
  removeTag: PropTypes.func.isRequired,
  tag: PropTypes.object.isRequired,
  user: PropTypes.object.isRequired
};

export default withStyles(RestaurantTag, s);
