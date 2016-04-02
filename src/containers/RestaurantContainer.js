import { connect } from 'react-redux';
import { removeTagFromRestaurant } from '../actions/restaurants';
import { showAddTagForm } from '../actions/listUi';
import { showMapAndInfoWindow } from '../actions/mapUi';
import Restaurant from '../components/Restaurant';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  listUiItem: state.listUi[ownProps.id] || {},
  showTagDelete: state.user.id !== undefined,
  ...ownProps
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
