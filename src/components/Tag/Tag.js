import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Tag.scss';

export const Tag = ({
  name,
  showDelete,
  onDeleteClicked,
  exclude
}) => {
  let deleteButton = null;
  if (showDelete) {
    deleteButton = (
      <button type="button" className={s.button} onClick={onDeleteClicked}>&times;</button>
    );
  }

  return (
    <div className={`${s.root} ${exclude ? s.exclude : ''}`}>
      {name}
      {deleteButton}
    </div>
  );
};

Tag.propTypes = {
  name: PropTypes.string.isRequired,
  showDelete: PropTypes.bool.isRequired,
  onDeleteClicked: PropTypes.func.isRequired,
  exclude: PropTypes.bool
};

export const undecorated = Tag;
export default withStyles(s)(Tag);
