import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { showInfoWindow, hideInfoWindow } from '../actions/mapUi';
import { getMarkerSettingsForId } from '../selectors/mapUi';
import { RestaurantMarker } from '../components/RestaurantMarker';

const mapStateToProps = (state, ownProps) => {
  const { index, baseZIndex, mapHolderRef } = ownProps;
  return {
    restaurant: getRestaurantById(state, ownProps.id),
    showInfoWindow: getMarkerSettingsForId(state, ownProps.id).showInfoWindow || false,
    index, baseZIndex, mapHolderRef
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleMarkerClick() {
    dispatch(showInfoWindow(ownProps.id));
  },
  handleMarkerClose() {
    dispatch(hideInfoWindow(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMarker);
