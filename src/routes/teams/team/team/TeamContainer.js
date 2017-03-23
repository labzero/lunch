import { connect } from 'react-redux';
import { injectIntl } from 'react-intl';
import { addUser, fetchUsersIfNeeded, removeUser } from '../../../../actions/users';
import { isUserListReady } from '../../../../selectors';
import { getTeamBySlug } from '../../../../selectors/teams';
import { getCurrentUser } from '../../../../selectors/user';
import { getUsers } from '../../../../selectors/users';
import Team from './Team';

const mapStateToProps = (state, ownProps) => ({
  currentUser: getCurrentUser(state),
  users: getUsers(state),
  userListReady: isUserListReady(state),
  team: getTeamBySlug(state, ownProps.teamSlug),
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
  injectIntl(Team)
);
