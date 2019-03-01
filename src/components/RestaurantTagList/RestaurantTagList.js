import PropTypes from 'prop-types';
import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantTagList.scss';
import TagContainer from '../Tag/TagContainer';

const RestaurantTagList = ({ ids, removeTag, loggedIn }) => (
  <ul className={`${s.root} ${ids.length === 0 ? s.empty : ''}`}>
    {ids.map(tagId => {
      const boundRemoveTag = () => { removeTag(tagId); };
      return (
        <li className={s.tagItem} key={`restaurantTag_${tagId}`}>
          <TagContainer id={tagId} showDelete={loggedIn} onDeleteClicked={boundRemoveTag} />
        </li>
      );
    })}
  </ul>
);

RestaurantTagList.propTypes = {
  ids: PropTypes.array.isRequired,
  removeTag: PropTypes.func.isRequired,
  loggedIn: PropTypes.bool.isRequired
};

export default withStyles(s)(RestaurantTagList);
