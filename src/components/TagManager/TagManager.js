import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagManager.scss';
import TagContainer from '../../containers/TagContainer';

const TagManager = ({ tags }) => (
  <div className={s.root}>
    <ul className={s.list}>
      {tags.map(item => (
        <li className={s.item} key={item.id}>
          <TagContainer
            id={item.id}
            name={item.name}
          />
        </li>
      ))}
    </ul>
  </div>
);

TagManager.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired
  }))
};

export default withStyles(TagManager, s);
