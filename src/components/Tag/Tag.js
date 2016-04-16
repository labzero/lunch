import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Tag.scss';

export const _Tag = ({
  name,
  showDelete,
  onDeleteClicked
}) => {
  let deleteButton = null;
  if (showDelete) {
    deleteButton = (
      <button className={s.button} onClick={onDeleteClicked}>&times;</button>
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
  name: PropTypes.string.isRequired,
  showDelete: PropTypes.bool.isRequired,
  onDeleteClicked: PropTypes.func.isRequired
};

export default withStyles(s)(_Tag);
