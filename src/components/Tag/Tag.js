import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Tag.scss';

export const _Tag = ({
  name,
  user,
  handleClick
}) => {
  const loggedIn = user.id !== undefined;

  let deleteButton = null;
  if (loggedIn) {
    deleteButton = (
      <button className={s.button} onClick={handleClick}>&times;</button>
    );
  }

  return (
    <div className={s.root}>
      {name}
      {deleteButton}
    </div>
  );
};

_Tag.propTypes = {
  id: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired,
  handleClick: PropTypes.func.isRequired
};

export default withStyles(_Tag, s);
