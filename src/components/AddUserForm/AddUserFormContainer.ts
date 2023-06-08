import { connect } from "react-redux";
import { addUser } from "../../actions/users";
import { currentUserHasRole, isUserListReady } from "../../selectors";
import AddUserForm from "./AddUserForm";
import { Dispatch, State, User } from "../../interfaces";

const mapStateToProps = (state: State) => ({
  hasGuestRole: currentUserHasRole(state, "guest"),
  hasMemberRole: currentUserHasRole(state, "member"),
  hasOwnerRole: currentUserHasRole(state, "owner"),
  userListReady: isUserListReady(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  addUserToTeam: (payload: Partial<User>) => dispatch(addUser(payload)),
});

export default connect(mapStateToProps, mapDispatchToProps)(AddUserForm);
