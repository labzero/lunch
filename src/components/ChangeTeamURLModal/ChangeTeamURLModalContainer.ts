import { connect } from "react-redux";
import { updateTeam } from "../../actions/team";
import { hideModal } from "../../actions/modals";
import { Dispatch, State, Team } from "../../interfaces";
import { getTeam } from "../../selectors/team";
import ChangeTeamURLModal from "./ChangeTeamURLModal";

const modalName = "changeTeamURL";

const mapStateToProps = (state: State) => ({
  host: state.host,
  team: getTeam(state),
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  },
  updateTeam: (payload: Partial<Team>) => dispatch(updateTeam(payload)),
});

export default connect(mapStateToProps, mapDispatchToProps)(ChangeTeamURLModal);
