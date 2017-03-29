import React, { PropTypes } from 'react';
import TagManagerItemContainer from '../TagManagerItem/TagManagerItemContainer';

const TagManager = ({ tags }) => (
  <ul>
    {tags.map(id => <TagManagerItemContainer id={id} key={`tagManagerItem_${id}`} />)}
  </ul>
);

TagManager.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.number).isRequired
};

export default TagManager;
