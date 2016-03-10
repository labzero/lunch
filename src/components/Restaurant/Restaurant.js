import React, { PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import RestaurantAddTagFormContainer from '../../containers/RestaurantAddTagFormContainer';
import RestaurantTagContainer from '../../containers/RestaurantTagContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Restaurant.scss';

const Restaurant = ({ id, name, address, votes, tags, user, isAddingTags, showAddTagForm, hideAddTagForm }) => {
  const loggedIn = typeof user.id === 'number';

  let deleteButton = null;
  let voteButton = null;
  if (loggedIn) {
    voteButton = <RestaurantVoteButtonContainer {...{ id, votes }} />;
    deleteButton = (
      <div className={s.deleteButtonContainer}>
        <RestaurantDeleteButtonContainer {...{ id }} />
      </div>
    );
  }

  let addTagArea = null;
  if (tags !== undefined && loggedIn) {
    if (isAddingTags) {
      addTagArea = <RestaurantAddTagFormContainer {...{ id }} />;
    } else {
      addTagArea = <button onClick={showAddTagForm}>add tag</button>;
    }
  }

  let tagsArea = null;
  if (tags !== undefined) {
    tagsArea = (
      <div>
        <ul>
          {tags.map(tag => <li><RestaurantTagContainer key={tag.id} {...tag} /></li>)}
        </ul>
        {addTagArea}
      </div>
    );
  }

  return (
    <div className={s.root}>
      <div className={s.header}>
        <h2 className={s.heading}>{name}</h2>
        <div className={s.voteButtonContainer}>
          {votes.length} {votes.length === 1 ? 'vote' : 'votes'}
          &nbsp;
          {voteButton}
        </div>
      </div>
      {address}
      {tagsArea}
      {deleteButton}
    </div>
  );
};

Restaurant.propTypes = {
  id: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  address: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired,
  votes: PropTypes.array.isRequired,
  tags: PropTypes.array,
  isAddingTags: PropTypes.bool
};

export default withStyles(Restaurant, s);
