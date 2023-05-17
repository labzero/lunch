import { connect } from "react-redux";
import { hideModal } from "../../actions/modals";
import ConfirmModal from "./ConfirmModal";

const modalName = "confirm";

const mapStateToProps = (state) => ({
  actionLabel: state.modals[modalName].actionLabel,
  body: state.modals[modalName].body,
  action: state.modals[modalName].action,
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  hideModal: () => dispatch(hideModal("confirm")),
});

const mergeProps = (stateProps, dispatchProps) => ({
  ...stateProps,
  ...dispatchProps,
  handleSubmit: () => {
    dispatchProps.dispatch(stateProps.action);
    dispatchProps.hideModal();
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(ConfirmModal);
