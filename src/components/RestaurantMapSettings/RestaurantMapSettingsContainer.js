import { connect } from 'react-redux';
import { setShowPOIs, setShowUnvoted } from '../../actions/mapUi';
import { flashSuccess } from '../../actions/flash';
import { updateTeam } from '../../actions/team';
import RestaurantMapSettings from './RestaurantMapSettings';

const mapStateToProps = state => ({
  showPOIs: state.mapUi.showPOIs,
  showUnvoted: state.mapUi.showUnvoted,
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  setDefaultZoom: () => dispatch(updateTeam({ defaultZoom: ownProps.map.getZoom() }))
    .then(() => dispatch(flashSuccess('Default zoom level set for team.'))),
  setShowUnvoted: event => dispatch(setShowUnvoted(event.target.checked)),
  setShowPOIs: event => dispatch(setShowPOIs(event.target.checked))
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMapSettings);
