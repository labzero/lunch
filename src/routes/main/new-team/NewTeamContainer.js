import { connect } from "react-redux";
import NewTeam from "./NewTeam";
import { setCenter } from "../../../actions/mapUi";
import { createTeam } from "../../../actions/teams";
import { getCenter } from "../../../selectors/mapUi";

const mapStateToProps = (state) => ({
  center: getCenter(state),
});

const mapDispatchToProps = (dispatch) => ({
  createTeam: (payload) => dispatch(createTeam(payload)),
  setCenter: (center) => dispatch(setCenter(center)),
});

export default connect(mapStateToProps, mapDispatchToProps)(NewTeam);
