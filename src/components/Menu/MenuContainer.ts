import { connect } from "react-redux";
import { State } from "../../interfaces";
import { getCurrentUser } from "../../selectors/user";
import { getTeam } from "../../selectors/team";
import { currentUserHasRole } from "../../selectors";
import Menu, { MenuProps } from "./Menu";

const mapStateToProps = (
  state: State,
  ownProps: Pick<MenuProps, "closeMenu" | "open">
) => ({
  hasGuestRole: currentUserHasRole(state, "guest"),
  hasMemberRole: currentUserHasRole(state, "member"),
  host: state.host,
  open: ownProps.open,
  team: getTeam(state),
  user: getCurrentUser(state),
});

export default connect(mapStateToProps)(Menu);
