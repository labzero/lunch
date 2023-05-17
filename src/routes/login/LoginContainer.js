import { connect } from "react-redux";
import Login from "./Login";

const mapStateToProps = (state, ownProps) => ({
  host: state.host,
  team: ownProps.team,
  next: ownProps.next,
});

export default connect(mapStateToProps)(Login);
