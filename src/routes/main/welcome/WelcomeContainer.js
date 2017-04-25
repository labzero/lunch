import { connect } from 'react-redux';
import { updateCurrentUser } from '../../../actions/user';
import history from '../../../core/history';
import { getCurrentUser } from '../../../selectors/user';
import Welcome from './Welcome';

const mapStateToProps = state => ({
  host: state.host,
  user: getCurrentUser(state)
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, {
  updateCurrentUser: payload => dispatchProps.dispatch(updateCurrentUser(payload)).then(() => {
    const team = ownProps.team;
    if (team) {
      window.location.href = `//${team}.${stateProps.host}${ownProps.next}`;
    } else if (ownProps.next) {
      history.push(ownProps.next);
    } else {
      history.push('/');
    }
  })
});

export default connect(
  mapStateToProps,
  null,
  mergeProps
)(Welcome);
