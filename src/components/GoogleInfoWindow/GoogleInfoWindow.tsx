import React, { Component } from "react";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import Button from "react-bootstrap/Button";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "./GoogleInfoWindow.scss";

let google: typeof window.google;

if (canUseDOM) {
  google = window.google;
}

interface GoogleInfoWindowProps {
  addRestaurant: (restaurant: google.maps.places.PlaceResult) => void;
  map: google.maps.Map;
  placeId: string;
}

class GoogleInfoWindow extends Component<GoogleInfoWindowProps> {
  placesService: google.maps.places.PlacesService;

  constructor(props: GoogleInfoWindowProps) {
    super(props);
    if (google) {
      this.placesService = new google.maps.places.PlacesService(props.map);
    }
  }

  handleClick = () => {
    const { addRestaurant, placeId } = this.props;

    this.placesService.getDetails({ placeId }, (result, status) => {
      if (status === google.maps.places.PlacesServiceStatus.OK && result) {
        addRestaurant(result);
      }
    });
  };

  render() {
    if (!google) {
      return null;
    }

    return (
      <div
        className={s.root}
        data-marker
        style={{
          zIndex: google.maps.Marker.MAX_ZINDEX * 2,
        }}
      >
        <div className={s.buttonContainer}>
          <Button size="lg" variant="primary" onClick={this.handleClick}>
            Add to Lunch
          </Button>
        </div>
      </div>
    );
  }
}

export default withStyles(s)(GoogleInfoWindow);
