import { connect } from 'react-redux';
import { getCenter } from '../../selectors/mapUi';
import { clearCenter, setCenter } from '../../actions/mapUi';
import TeamMap from './TeamMap';

const mapStateToProps = (state) => ({
  center: getCenter(state)
});

const mapDispatchToProps = (dispatch) => ({
  clearCenter: () => dispatch(clearCenter()),
  setCenter: center => dispatch(setCenter(center))
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamMap);
