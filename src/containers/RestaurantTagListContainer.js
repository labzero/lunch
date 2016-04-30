import { connect } from 'react-redux';
import { getTagsForRestaurant } from '../selectors/restaurants';
import { removeTagFromRestaurant } from '../actions/restaurants';
import RestaurantTagList from '../components/RestaurantTagList';

const mapStateToProps = (state, ownProps) => ({
  ids: getTagsForRestaurant(state, ownProps.id),
  loggedIn: state.user.id !== undefined
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  removeTag(id) {
    dispatch(removeTagFromRestaurant(ownProps.id, id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantTagList);
