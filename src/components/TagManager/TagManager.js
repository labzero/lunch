import React, { PropTypes } from 'react';
import TagManagerItemContainer from '../TagManagerItem/TagManagerItemContainer';

const TagManager = ({ tags }) => {
  if (!tags.length) {
    return (
      <p>
        Once you add tags to restaurants, come back to this page and
        you&#39;ll be able to count their uses and remove them!
      </p>
    );
  }

  return (
    <ul>
      {tags.map(id => <TagManagerItemContainer id={id} key={`tagManagerItem_${id}`} />)}
    </ul>
  );
};

TagManager.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.number).isRequired
};

export default TagManager;
