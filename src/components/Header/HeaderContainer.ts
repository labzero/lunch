import { connect } from "react-redux";
import { State } from "../../interfaces";
import { isLoggedIn } from "../../selectors/user";
import Header from "./Header";

const mapStateToProps = (state: State, ownProps: { path: string }) => ({
  flashes: state.flashes,
  loggedIn: isLoggedIn(state),
  path: ownProps.path,
});

export default connect(mapStateToProps)(Header);
