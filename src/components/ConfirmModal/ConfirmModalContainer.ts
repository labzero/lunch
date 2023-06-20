import { connect } from "react-redux";
import { confirmableActions } from "../../actions";
import { hideModal } from "../../actions/modals";
import ConfirmModal from "./ConfirmModal";
import {
  ConfirmModal as ConfirmModalType,
  Dispatch,
  State,
} from "../../interfaces";

const modalName = "confirm";

const mapStateToProps = <T extends keyof typeof confirmableActions>(
  state: State
) => state.modals[modalName] as ConfirmModalType<T>;

const mapDispatchToProps = (dispatch: Dispatch) => ({
  dispatch,
  hideModal: () => dispatch(hideModal("confirm")),
});

const mergeProps = <T extends keyof typeof confirmableActions>(
  stateProps: ConfirmModalType<T>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  handleSubmit: () => {
    dispatchProps.dispatch(
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      confirmableActions[stateProps.action](...stateProps.actionArgs)
    );
    dispatchProps.hideModal();
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(ConfirmModal);
