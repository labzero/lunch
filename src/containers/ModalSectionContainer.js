import { connect } from 'react-redux';
import ModalSection from '../components/ModalSection';

const mapStateToProps = state => ({
  modals: state.modals
});

export default connect(mapStateToProps)(ModalSection);
