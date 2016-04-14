import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagManager.scss';
import TagContainer from '../../containers/TagContainer';

const TagManager = ({ tags, showDelete, handleDeleteClicked }) => (
  <div className={s.root}>
    <ul className={s.list}>
      {tags.map(item => {
        const boundHandleDeleteClicked = handleDeleteClicked.bind(undefined, item.id);

        return (
          <li key={item.id}>
            <span className={s.tagContainer}>
              <TagContainer
                id={item.id}
                name={item.name}
                showDelete={showDelete}
                onDeleteClicked={boundHandleDeleteClicked}
              />
            </span>
            ({item.restaurant_count})
          </li>
        );
      })}
    </ul>
  </div>
);

TagManager.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired
  })),
  showDelete: PropTypes.bool.isRequired,
  handleDeleteClicked: PropTypes.func.isRequired
};

export default withStyles(TagManager, s);
