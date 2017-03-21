import { connect } from 'react-redux';
import { injectIntl } from 'react-intl';
import { addUser, fetchUsersIfNeeded } from '../../../../actions/users';
import { isAdminUserListReady } from '../../../../selectors';
import { getUsers } from '../../../../selectors/users';
import Admin from './Admin';

const mapStateToProps = (state, ownProps) => ({
  users: getUsers(state, ownProps.teamSlug),
  adminUserListReady: isAdminUserListReady(state),
  title: ownProps.title
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  addUserToTeam: email => dispatch(addUser(email)),
  fetchUsersIfNeeded() {
    dispatch(fetchUsersIfNeeded(ownProps.teamSlug));
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(
  injectIntl(Admin)
);
