import { connect } from "react-redux";
import { getTeam } from "../../selectors/team";
import { removeTeam } from "../../actions/team";
import { hideModal } from "../../actions/modals";
import { Dispatch, State } from "../../interfaces";
import DeleteTeamModal from "./DeleteTeamModal";

const modalName = "deleteTeam";

const mapStateToProps = (state: State) => ({
  host: state.host,
  team: getTeam(state),
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  },
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  deleteTeam: () => dispatchProps.dispatch(removeTeam()),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(DeleteTeamModal);
