import { connect } from "react-redux";
import { getCurrentUser } from "../../selectors/user";
import { getTeam } from "../../selectors/team";
import { currentUserHasRole } from "../../selectors";
import Menu from "./Menu";

const mapStateToProps = (state, ownProps) => ({
  hasGuestRole: currentUserHasRole(state, "guest"),
  hasMemberRole: currentUserHasRole(state, "member"),
  host: state.host,
  open: ownProps.open,
  team: getTeam(state),
  user: getCurrentUser(state),
});

export default connect(mapStateToProps)(Menu);
