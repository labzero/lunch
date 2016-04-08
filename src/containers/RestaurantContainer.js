import { connect } from 'react-redux';
import { removeTagFromRestaurant } from '../actions/restaurants';
import { showMapAndInfoWindow } from '../actions/mapUi';
import { showAddTagForm } from '../actions/listUi';
import Restaurant from '../components/Restaurant';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  listUiItem: state.listUi[ownProps.id] || {},
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
