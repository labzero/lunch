import { connect } from "react-redux";
import { getTeam } from "../../selectors/team";
import { updateTeam } from "../../actions/team";
import { hideModal } from "../../actions/modals";
import ChangeTeamURLModal from "./ChangeTeamURLModal";

const modalName = "changeTeamURL";

const mapStateToProps = (state) => ({
  host: state.host,
  team: getTeam(state),
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch) => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  },
  updateTeam: (payload) => dispatch(updateTeam(payload)),
});

export default connect(mapStateToProps, mapDispatchToProps)(ChangeTeamURLModal);
