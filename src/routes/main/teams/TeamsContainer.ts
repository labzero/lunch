import { connect } from "react-redux";
import { showModal } from "../../../actions/modals";
import { ConfirmOpts, Dispatch, State } from "../../../interfaces";
import { getCurrentUser } from "../../../selectors/user";
import { getTeams } from "../../../selectors/teams";
import Teams from "./Teams";

const mapStateToProps = (state: State) => ({
  host: state.host,
  user: getCurrentUser(state),
  teams: getTeams(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  confirm: (opts: ConfirmOpts<"removeUser">) =>
    dispatch(showModal("confirm", opts)),
  dispatch,
});

export default connect(mapStateToProps, mapDispatchToProps)(Teams);
