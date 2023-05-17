import { connect } from "react-redux";
import { injectIntl } from "react-intl";
import { addUser } from "../../actions/users";
import { currentUserHasRole, isUserListReady } from "../../selectors";
import AddUserForm from "./AddUserForm";

const mapStateToProps = (state) => ({
  hasGuestRole: currentUserHasRole(state, "guest"),
  hasMemberRole: currentUserHasRole(state, "member"),
  hasOwnerRole: currentUserHasRole(state, "owner"),
  userListReady: isUserListReady(state),
});

const mapDispatchToProps = (dispatch) => ({
  addUserToTeam: (payload) => dispatch(addUser(payload)),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(injectIntl(AddUserForm));
