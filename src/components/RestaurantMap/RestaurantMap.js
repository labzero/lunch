import React, { PropTypes } from 'react';
import { GoogleMapLoader, GoogleMap, Marker } from 'react-google-maps';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMap.scss';

const RestaurantMap = ({ items, latLng }) => {console.log('hi'); return (
  <section style={{ height: '500px' }}>
    <GoogleMapLoader
      containerElement={
        <div
          style={{
            height: '100%'
          }}
        />
      }
      googleMapElement={
        <GoogleMap
          ref={(map) => console.log(map)}
          defaultZoom={16}
          defaultCenter={latLng}
        >
          {items.map((item, index) => (
              <Marker
                position={{ lat: item.lat, lng: item.lng }}
                key={index}
              />
            )
          )}
        </GoogleMap>
      }
    />
  </section>
);};

export default withStyles(RestaurantMap, s);
