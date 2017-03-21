import { connect } from 'react-redux';
import { injectIntl } from 'react-intl';
import { addUser, fetchUsersIfNeeded, removeUser } from '../../../../actions/users';
import { isAdminUserListReady } from '../../../../selectors';
import { getCurrentUser } from '../../../../selectors/user';
import { getUsers } from '../../../../selectors/users';
import Admin from './Admin';

const mapStateToProps = (state, ownProps) => ({
  userId: getCurrentUser(state).id,
  users: getUsers(state, ownProps.teamSlug),
  adminUserListReady: isAdminUserListReady(state),
  title: ownProps.title
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  addUserToTeam: payload => dispatch(addUser(ownProps.teamSlug, payload)),
  fetchUsersIfNeeded() {
    dispatch(fetchUsersIfNeeded(ownProps.teamSlug));
  },
  removeUserFromTeam: id => dispatch(removeUser(ownProps.teamSlug, id))
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(
  injectIntl(Admin)
);
