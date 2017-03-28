import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagManager.scss';
import TagManagerItemContainer from '../TagManagerItem/TagManagerItemContainer';

const TagManager = ({ tags }) => (
  <ul className={s.list}>
    {tags.map(id => <TagManagerItemContainer id={id} key={`tagManagerItem_${id}`} />)}
  </ul>
);

TagManager.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.number).isRequired
};

export default withStyles(s)(TagManager);
