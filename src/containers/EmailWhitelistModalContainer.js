import { connect } from 'react-redux';
import { hideModal } from '../actions/modals';
import EmailWhitelistModal from '../components/EmailWhitelistModal';

const modalName = 'emailWhitelist';

const mapStateToProps = state => ({
  shown: !!state.modals[modalName].shown
});

const mapDispatchToProps = dispatch => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EmailWhitelistModal);
