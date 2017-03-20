import { connect } from 'react-redux';
import { showModal } from '../../actions/modals';
import Footer from './Footer';

const mapStateToProps = state => ({ user: state.user });

const mapDispatchToProps = (dispatch, ownProps) => ({
  manageTags() {
    dispatch(showModal('tagManager', { teamSlug: ownProps.teamSlug }));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Footer);
