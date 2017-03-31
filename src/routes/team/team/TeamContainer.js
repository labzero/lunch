import { connect } from 'react-redux';
import { injectIntl } from 'react-intl';
import { addUser, changeUserRole, fetchUsersIfNeeded, removeUser } from '../../../actions/users';
import { isUserListReady } from '../../../selectors';
import { getTeam } from '../../../selectors/team';
import { getCurrentUser } from '../../../selectors/user';
import { getUsers } from '../../../selectors/users';
import Team from './Team';

const mapStateToProps = state => ({
  currentUser: getCurrentUser(state),
  users: getUsers(state),
  userListReady: isUserListReady(state),
  team: getTeam(state)
});

const mapDispatchToProps = (dispatch) => ({
  addUserToTeam: payload => dispatch(addUser(payload)),
  changeUserRole: (id, type) => dispatch(changeUserRole(id, type)),
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
