import PropTypes from 'prop-types';
import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import s from './TagManagerItem.scss';
import TagContainer from '../Tag/TagContainer';

const TagManagerItem = ({ tag, showDelete, handleDeleteClicked }) => (
  <li>
    <span className={s.tagContainer}>
      <TagContainer
        id={tag.id}
        showDelete={showDelete}
        onDeleteClicked={handleDeleteClicked}
      />
    </span>
    (
    {tag.restaurant_count}
)
  </li>
);

TagManagerItem.propTypes = {
  tag: PropTypes.object.isRequired,
  showDelete: PropTypes.bool.isRequired,
  handleDeleteClicked: PropTypes.func.isRequired,
};

export default withStyles(s)(TagManagerItem);
