import React, { Component, PropTypes } from 'react';
import GoogleMap from 'google-map-react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import HereMarker from '../../components/HereMarker';
import { GOOGLE_MAP_ZOOM } from '../../constants';
import googleMapOptions from '../../constants/googleMapOptions';
import defaultCoords from '../../constants/defaultCoords';
import s from './TeamMap.scss';

class TeamMap extends Component {
  static propTypes = {
    center: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired
    }),
    setCenter: PropTypes.func.isRequired
  }

  static defaultProps = {
    center: defaultCoords
  }

  setMap = ({ map }) => {
    this.map = map;
    map.addListener('bounds_changed', () => {
      const center = map.getCenter();
      this.props.setCenter({
        lat: center.lat(),
        lng: center.lng()
      });
    });
  };

  render() {
    const { center } = this.props;

    return (
      <div>
        <div className={s.mapContainer}>
          <GoogleMap
            center={center}
            defaultZoom={GOOGLE_MAP_ZOOM}
            defaultCenter={TeamMap.defaultProps.center}
            onGoogleApiLoaded={this.setMap}
            options={googleMapOptions}
            yesIWantToUseGoogleMapApiInternals
          />
          <div className={s.hereCenterer}>
            <HereMarker />
          </div>
        </div>
        Lat: {center.lat.toFixed(6)};
        Lng: {center.lng.toFixed(6)};
      </div>
    );
  }
}

export default withStyles(s)(TeamMap);
