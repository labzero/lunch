import { connect } from 'react-redux';
import { showModal } from '../actions/modals';
import Footer from '../components/Footer';

const mapStateToProps = null;

const mapDispatchToProps = dispatch => ({
  manageTags() {
    dispatch(showModal('tagManager'));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Footer);
