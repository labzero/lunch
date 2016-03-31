import { connect } from 'react-redux';
import { setShowUnvoted } from '../actions/mapUi';
import RestaurantMapSettings from '../components/RestaurantMapSettings';

const mapStateToProps = state => ({
  showUnvoted: state.mapUi.showUnvoted,
});

const mapDispatchToProps = dispatch => ({
  setShowUnvoted(event) {
    dispatch(setShowUnvoted(event.target.checked));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMapSettings);
