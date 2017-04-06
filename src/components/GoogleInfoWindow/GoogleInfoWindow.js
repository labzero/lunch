import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import Button from 'react-bootstrap/lib/Button';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './GoogleInfoWindow.scss';

let google = { maps: {
  Marker: { MAX_ZINDEX: 1000000 },
  places: { PlacesService: () => {}, PlacesServiceStatus: {} }
} };
if (canUseDOM) {
  google = window.google || google;
}

class GoogleInfoWindow extends Component {
  static propTypes = {
    addRestaurant: PropTypes.func.isRequired,
    map: PropTypes.any.isRequired,
    placeId: PropTypes.string.isRequired
  };

  constructor(props) {
    super(props);
    this.placesService = new google.maps.places.PlacesService(props.map);
  }

  handleClick = () => {
    const { addRestaurant, placeId } = this.props;

    this.placesService.getDetails({ placeId }, (result, status) => {
      if (status === google.maps.places.PlacesServiceStatus.OK) {
        addRestaurant(result);
      }
    });
  };

  render() {
    return (
      <div
        className={s.root}
        data-marker
        style={{ zIndex: google.maps.Marker.MAX_ZINDEX * 2 }}
      >
        <div className={s.buttonContainer}>
          <Button
            bsSize="large"
            bsStyle="primary"
            onClick={this.handleClick}
          >Add to Lunch</Button>
        </div>
      </div>
    );
  }
}

export default withStyles(s)(GoogleInfoWindow);
