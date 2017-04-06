import { connect } from 'react-redux';
import { setShowPOIs, setShowUnvoted } from '../../actions/mapUi';
import RestaurantMapSettings from './RestaurantMapSettings';

const mapStateToProps = state => ({
  showPOIs: state.mapUi.showPOIs,
  showUnvoted: state.mapUi.showUnvoted,
});

const mapDispatchToProps = dispatch => ({
  setShowUnvoted: event => {
    dispatch(setShowUnvoted(event.target.checked));
  },
  setShowPOIs: event => {
    dispatch(setShowPOIs(event.target.checked));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMapSettings);
