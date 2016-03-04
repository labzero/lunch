import { connect } from 'react-redux';
import Flash from '../../components/Flash';
import { expireFlash } from '../../actions/flash';

const mapStateToProps = null;

const mapDispatchToProps = (dispatch, ownProps) => ({
  expireFlash() {
    dispatch(expireFlash(ownProps.id));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(Flash);
