import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import HereMarker from '../../components/HereMarker';
import { GOOGLE_MAP_ZOOM } from '../../constants';
import defaultCoords from '../../constants/defaultCoords';
import googleMapOptions from '../../helpers/googleMapOptions';
import loadComponent from '../../helpers/loadComponent';
import s from './TeamMap.scss';

let GoogleMap = () => null;

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

  componentDidMount() {
    loadComponent(() => require.ensure([], require => require('google-map-react').default, 'map')).then((map) => {
      GoogleMap = map;
      this.forceUpdate();
    });
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
      <div className={s.root}>
        <GoogleMap
          center={center}
          defaultZoom={GOOGLE_MAP_ZOOM}
          defaultCenter={TeamMap.defaultProps.center}
          onGoogleApiLoaded={this.setMap}
          options={googleMapOptions()}
          yesIWantToUseGoogleMapApiInternals
        />
        <div className={s.hereCenterer}>
          <HereMarker />
        </div>
      </div>
    );
  }
}

export default withStyles(s)(TeamMap);
