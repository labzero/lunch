import { connect } from "react-redux";
import { flashSuccess } from "../../actions/flash";
import { updateTeam } from "../../actions/team";
import { Dispatch, State, Team } from "../../interfaces";
import { getCenter } from "../../selectors/mapUi";
import { getTeam } from "../../selectors/team";
import TeamForm from "./TeamForm";

const mapStateToProps = (state: State) => ({
  center: getCenter(state),
  team: getTeam(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  updateTeam: (payload: Partial<Team>) =>
    dispatch(updateTeam(payload)).then(() =>
      dispatch(flashSuccess("Team info updated."))
    ),
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamForm);
