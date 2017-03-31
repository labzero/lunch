import { connect } from 'react-redux';
import { getCenter } from '../../selectors/mapUi';
import { setCenter } from '../../actions/mapUi';
import TeamMap from './TeamMap';

const mapStateToProps = (state) => ({
  center: getCenter(state)
});

const mapDispatchToProps = (dispatch) => ({
  setCenter: center => dispatch(setCenter(center))
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamMap);
