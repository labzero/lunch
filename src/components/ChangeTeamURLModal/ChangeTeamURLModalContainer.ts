import { connect } from "react-redux";
import { ThunkDispatch } from "@reduxjs/toolkit";
import { updateTeam } from "../../actions/team";
import { hideModal } from "../../actions/modals";
import { Action, State, Team } from "../../interfaces";
import { getTeam } from "../../selectors/team";
import ChangeTeamURLModal from "./ChangeTeamURLModal";

const modalName = "changeTeamURL";

const mapStateToProps = (state: State) => ({
  host: state.host,
  team: getTeam(state),
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (
  dispatch: ThunkDispatch<State, unknown, Action>
) => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  },
  updateTeam: (payload: Partial<Team>) => dispatch(updateTeam(payload)),
});

export default connect(mapStateToProps, mapDispatchToProps)(ChangeTeamURLModal);
