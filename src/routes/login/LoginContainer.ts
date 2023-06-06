import { connect } from "react-redux";
import Login from "./Login";
import { State } from "../../interfaces";

const mapStateToProps = (
  state: State,
  ownProps: { team?: string; next?: string }
) => ({
  host: state.host,
  team: ownProps.team,
  next: ownProps.next,
});

export default connect(mapStateToProps)(Login);
