import { connect } from 'react-redux';
import { changeRestaurantName } from '../actions/restaurants';
import { hideEditNameForm, setEditNameFormValue } from '../actions/listUi';
import RestaurantNameForm from '../components/RestaurantNameForm';

const mapStateToProps = (state, ownProps) => {
  const listUiItem = state.listUi[ownProps.id] || {};
  return {
    editNameFormValue: listUiItem.editNameFormValue || ''
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  hideEditNameForm() {
    dispatch(hideEditNameForm(ownProps.id));
  },
  setEditNameFormValue(event) {
    dispatch(setEditNameFormValue(ownProps.id, event.target.value));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  changeRestaurantName() {
    dispatchProps.dispatch(changeRestaurantName(ownProps.id, stateProps.editNameFormValue));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantNameForm);
