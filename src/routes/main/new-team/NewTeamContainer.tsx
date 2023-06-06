import { connect } from "react-redux";
import NewTeam from "./NewTeam";
import { setCenter } from "../../../actions/mapUi";
import { createTeam } from "../../../actions/teams";
import { Dispatch, LatLng, State, Team } from "../../../interfaces";
import { getCenter } from "../../../selectors/mapUi";

const mapStateToProps = (state: State) => ({
  center: getCenter(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  createTeam: (payload: Partial<Team>) => dispatch(createTeam(payload)),
  setCenter: (center: LatLng) => dispatch(setCenter(center)),
});

export default connect(mapStateToProps, mapDispatchToProps)(NewTeam);
