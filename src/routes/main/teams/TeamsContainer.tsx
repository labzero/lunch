import { connect } from "react-redux";
import { showModal } from "../../../actions/modals";
import { removeUser } from "../../../actions/users";
import { ConfirmOpts, Dispatch, State, Team } from "../../../interfaces";
import { getCurrentUser } from "../../../selectors/user";
import { getTeams } from "../../../selectors/teams";
import Teams from "./Teams";

const mapStateToProps = (state: State) => ({
  host: state.host,
  user: getCurrentUser(state),
  teams: getTeams(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  confirm: (opts: ConfirmOpts) => dispatch(showModal("confirm", opts)),
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  leaveTeam: (team: Team) => removeUser(stateProps.user!.id, team),
});

export default connect(mapStateToProps, mapDispatchToProps, mergeProps)(Teams);
