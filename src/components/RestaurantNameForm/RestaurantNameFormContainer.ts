import { ChangeEvent, FormEvent } from "react";
import { connect } from "react-redux";
import { changeRestaurantName } from "../../actions/restaurants";
import { hideEditNameForm, setEditNameFormValue } from "../../actions/listUi";
import { Dispatch, State } from "../../interfaces";
import { getListUiItemForId } from "../../selectors/listUi";
import RestaurantNameForm from "./RestaurantNameForm";

interface OwnProps {
  id: number;
  name: string;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => {
  const listUiItem = getListUiItemForId(state, ownProps.id);
  return {
    editNameFormValue: listUiItem.editNameFormValue || "",
  };
};

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  hideEditNameForm: () => {
    dispatch(hideEditNameForm(ownProps.id));
  },
  setEditNameFormValue: (event: ChangeEvent<HTMLInputElement>) => {
    dispatch(setEditNameFormValue(ownProps.id, event.target.value));
  },
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>,
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  changeRestaurantName: (event: FormEvent<HTMLInputElement>) => {
    event.preventDefault();
    dispatchProps.dispatch(
      changeRestaurantName(ownProps.id, stateProps.editNameFormValue)
    );
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantNameForm);
