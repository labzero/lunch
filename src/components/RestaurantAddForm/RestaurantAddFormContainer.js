import { connect } from 'react-redux';
import { scroller } from 'react-scroll';
import { injectIntl } from 'react-intl';
import { getRestaurants } from '../../selectors/restaurants';
import { getTeamLatLng } from '../../selectors/team';
import { addRestaurant } from '../../actions/restaurants';
import { createTempMarker, clearTempMarker } from '../../actions/mapUi';
import RestaurantAddForm from './RestaurantAddForm';

// Keep a cache of terms[0] since our geosuggest library doesn't allow us to receive a label
// different than what is in the suggest dropdown
let suggestCache = {};

const mapStateToProps = state => ({
  latLng: getTeamLatLng(state),
  restaurants: getRestaurants(state)
});

const mapDispatchToProps = dispatch => ({
  getSuggestLabel: (suggest) => {
    if (suggest.terms !== undefined && suggest.terms.length > 0) {
      suggestCache[suggest.place_id] = suggest.terms[0].value;
    }
    return suggest.description;
  },
  createTempMarker: (result) => {
    const location = result.geometry.location;
    const marker = {
      label: suggestCache[location.place_id],
      latLng: {
        lat: location.lat(),
        lng: location.lng()
      }
    };
    dispatch(createTempMarker(marker));
  },
  clearTempMarker: () => {
    dispatch(clearTempMarker());
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  handleSuggestSelect: (suggestion, geosuggest) => {
    if (suggestion) {
      let name = suggestion.label;
      let address;
      const { placeId, location: { lat, lng } } = suggestion;
      const isEstablishment = suggestion.gmaps && suggestion.gmaps.types.indexOf('establishment') > -1;
      if (suggestCache[placeId] !== undefined && isEstablishment) {
        name = suggestCache[placeId];
      } else if (!isEstablishment) {
        name = name.split(',')[0];
      }
      if (suggestion.gmaps !== undefined) {
        address = suggestion.gmaps.formatted_address;
      }
      suggestCache = [];
      geosuggest.update('');
      geosuggest.showSuggests();
      const existingRestaurant = stateProps.restaurants.find(r => r.place_id === placeId);
      if (existingRestaurant === undefined) {
        dispatchProps.dispatch(addRestaurant(name, placeId, address, lat, lng));
      } else {
        scroller.scrollTo(`restaurantListItem_${existingRestaurant.id}`, {
          containerId: 'listContainer',
          offset: document.getElementById('listForms').offsetHeight,
          smooth: true,
        });
        scroller.scrollTo(`restaurantListItem_${existingRestaurant.id}`);
      }
    }
    dispatchProps.dispatch(clearTempMarker());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(injectIntl(RestaurantAddForm));
