import { connect } from "react-redux";
import { injectIntl } from "react-intl";
import { showModal } from "../../../actions/modals";
import {
  changeUserRole,
  fetchUsersIfNeeded,
  removeUser,
} from "../../../actions/users";
import { ConfirmOpts, Dispatch, State } from "../../../interfaces";
import { currentUserHasRole, isUserListReady } from "../../../selectors";
import { getTeam } from "../../../selectors/team";
import { getCurrentUser } from "../../../selectors/user";
import { getUsers } from "../../../selectors/users";
import Team from "./Team";

const mapStateToProps = (state: State) => ({
  changeTeamURLShown: !!state.modals.changeTeamURL,
  currentUser: getCurrentUser(state),
  deleteTeamShown: !!state.modals.deleteTeam,
  hasGuestRole: currentUserHasRole(state, "guest"),
  hasMemberRole: currentUserHasRole(state, "member"),
  hasOwnerRole: currentUserHasRole(state, "owner"),
  users: getUsers(state),
  userListReady: isUserListReady(state),
  team: getTeam(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  changeUserRole,
  confirm: (opts: ConfirmOpts) => dispatch(showModal("confirm", opts)),
  confirmChangeTeamURL: () => dispatch(showModal("changeTeamURL")),
  confirmDeleteTeam: () => dispatch(showModal("deleteTeam")),
  dispatch,
  fetchUsersIfNeeded() {
    dispatch(fetchUsersIfNeeded());
  },
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  removeUserFromTeam: (id: number) =>
    dispatchProps.dispatch(removeUser(id, stateProps.team)),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(injectIntl(Team));
