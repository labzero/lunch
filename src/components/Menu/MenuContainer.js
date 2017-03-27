import { connect } from 'react-redux';
import { getCurrentUser } from '../../selectors/user';
import { currentUserHasRole } from '../../selectors';
import Menu from './Menu';

const mapStateToProps = (state, ownProps) => ({
  hasGuestRole: currentUserHasRole(state, { role: 'guest', teamSlug: ownProps.teamSlug }),
  hasMemberRole: currentUserHasRole(state, { role: 'member', teamSlug: ownProps.teamSlug }),
  open: ownProps.open,
  teamSlug: ownProps.teamSlug,
  user: getCurrentUser(state)
});

export default connect(mapStateToProps)(Menu);
