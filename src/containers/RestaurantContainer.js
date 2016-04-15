import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getListUiItemForId } from '../selectors/listUi';
import { removeTagFromRestaurant } from '../actions/restaurants';
import { showMapAndInfoWindow } from '../actions/mapUi';
import { showAddTagForm } from '../actions/listUi';
import Restaurant from '../components/Restaurant';

const mapStateToProps = (state, ownProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  user: state.user,
  listUiItem: getListUiItemForId(state, ownProps.id)
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  showAddTagForm() {
    dispatch(showAddTagForm(ownProps.id));
  },
  showMapAndInfoWindow() {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  removeTag(id) {
    dispatch(removeTagFromRestaurant(ownProps.id, id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Restaurant);
