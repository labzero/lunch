import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagManager.scss';
import TagManagerItemContainer from '../../containers/TagManagerItemContainer';

const TagManager = ({ tags }) => (
  <div className={s.root}>
    <ul className={s.list}>
      {tags.map(id => <TagManagerItemContainer id={id} key={`tagManagerItem_${id}`} />)}
    </ul>
  </div>
);

TagManager.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.number).isRequired,
};

export default withStyles(TagManager, s);
