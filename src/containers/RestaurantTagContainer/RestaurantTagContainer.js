import { connect } from 'react-redux';
import { removeTagFromRestaurant } from '../../actions/restaurants';
import RestaurantTag from '../../components/RestaurantTag';

const mapStateToProps = (state, ownProps) => ({
  tag: state.tags.items.find(tag =>
    tag.id === ownProps.id
  )
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  removeTag() {
    dispatch(removeTagFromRestaurant(ownProps.restaurantId, ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantTag);
