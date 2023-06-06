import { connect } from "react-redux";
import { State } from "../../interfaces";
import { isLoggedIn } from "../../selectors/user";
import Header, { HeaderProps } from "./Header";

const mapStateToProps = (
  state: State,
  ownProps: Pick<HeaderProps, "path">
) => ({
  flashes: state.flashes,
  loggedIn: isLoggedIn(state),
  path: ownProps.path,
});

export default connect(mapStateToProps)(Header);
