import { connect } from "react-redux";
import { hideModal } from "../../actions/modals";
import ConfirmModal from "./ConfirmModal";
import { Dispatch, State } from "../../interfaces";

const modalName = "confirm";

const mapStateToProps = (state: State) => ({
  actionLabel: state.modals[modalName].actionLabel!,
  body: state.modals[modalName].body,
  action: state.modals[modalName].action,
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  dispatch,
  hideModal: () => dispatch(hideModal("confirm")),
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  handleSubmit: () => {
    dispatchProps.dispatch(stateProps.action!);
    dispatchProps.hideModal();
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(ConfirmModal);
