import { connect } from 'react-redux';
import { showEditNameForm, hideEditNameForm, setEditNameFormValue } from '../actions/listUi';
import RestaurantNameForm from '../components/RestaurantNameForm';

const mapStateToProps = (state, ownProps) => {
  const listUiItem = state.listUi[ownProps.id] || {};
  return {
    editNameFormValue: listUiItem.editNameFormValue || ''
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  setEditNameFormValue(value) {
    dispatch(setEditNameFormValue(ownProps.id, value));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantNameForm);
