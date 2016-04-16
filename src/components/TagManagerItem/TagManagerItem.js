import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagManagerItem.scss';
import TagContainer from '../../containers/TagContainer';

const TagManagerItem = ({ tag, showDelete, handleDeleteClicked }) => (
  <li>
    <span className={s.tagContainer}>
      <TagContainer
        id={tag.id}
        showDelete={showDelete}
        onDeleteClicked={handleDeleteClicked}
      />
    </span>
    ({tag.restaurant_count})
  </li>
);

TagManagerItem.propTypes = {
  tag: PropTypes.object.isRequired,
  showDelete: PropTypes.bool.isRequired,
  handleDeleteClicked: PropTypes.func.isRequired
};

export default withStyles(s)(TagManagerItem);
