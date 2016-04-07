import { connect } from 'react-redux';
import { removeTagFromRestaurant } from '../actions/restaurants';
import { showMapAndInfoWindow } from '../actions/mapUi';
import { showAddTagForm, showEditNameForm, setEditNameFormValue } from '../actions/listUi';
import Restaurant from '../components/Restaurant';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  listUiItem: state.listUi[ownProps.id] || {},
  shouldShowTagDelete: state.user.id !== undefined,
  ...ownProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  showAddTagForm() {
    dispatch(showAddTagForm(ownProps.id));
  },
  showMapAndInfoWindow() {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  showEditNameForm() {
    dispatch(setEditNameFormValue(ownProps.id, ownProps.name));
    dispatch(showEditNameForm(ownProps.id));
  },
  removeTag(id) {
    dispatch(removeTagFromRestaurant(ownProps.id, id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Restaurant);
