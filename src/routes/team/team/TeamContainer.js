import { connect } from 'react-redux';
import { injectIntl } from 'react-intl';
import { showModal } from '../../../actions/modals';
import { changeUserRole, fetchUsersIfNeeded, removeUser } from '../../../actions/users';
import { currentUserHasRole, isUserListReady } from '../../../selectors';
import { getTeam } from '../../../selectors/team';
import { getCurrentUser } from '../../../selectors/user';
import { getUsers } from '../../../selectors/users';
import Team from './Team';

const mapStateToProps = state => ({
  currentUser: getCurrentUser(state),
  hasGuestRole: currentUserHasRole(state, 'guest'),
  hasMemberRole: currentUserHasRole(state, 'member'),
  hasOwnerRole: currentUserHasRole(state, 'owner'),
  users: getUsers(state),
  userListReady: isUserListReady(state),
  team: getTeam(state)
});

const mapDispatchToProps = (dispatch) => ({
  changeUserRole: (id, type) => dispatch(changeUserRole(id, type)),
  confirm: opts => dispatch(showModal('confirm', opts)),
  confirmDeleteTeam: () => dispatch(showModal('deleteTeam')),
  fetchUsersIfNeeded() {
    dispatch(fetchUsersIfNeeded());
  },
  removeUserFromTeam: id => dispatch(removeUser(id))
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(
  injectIntl(Team)
);
