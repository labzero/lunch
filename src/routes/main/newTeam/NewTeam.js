import React, { Component, PropTypes } from 'react';
import Geosuggest from 'react-geosuggest';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import { TEAM_SLUG_REGEX } from '../../../constants';
import lzCoords from '../../../constants/lzCoords';
import TeamMapContainer from '../../../components/TeamMap/TeamMapContainer';
import history from '../../../core/history';

let google = { maps: { Geocoder: function Geocoder() { return {}; }, GeocoderStatus: {} } };
if (canUseDOM) {
  google = window.google || google;
}

class NewTeam extends Component {
  static propTypes = {
    center: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired
    }),
    createTeam: PropTypes.func.isRequired,
    setCenter: PropTypes.func.isRequired
  };

  static defaultProps = {
    center: lzCoords
  }

  constructor(props) {
    super(props);
    this.geocoder = new google.maps.Geocoder();
    this.state = {
      name: '',
      slug: '',
      address: ''
    };
  }

  getCoordsForMarker = (suggest) => {
    if (suggest !== null) {
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === google.maps.GeocoderStatus.OK) {
          const location = results[0].geometry.location;
          const center = {
            lat: location.lat(),
            lng: location.lng()
          };
          this.props.setCenter(center);
        }
      });
    }
  }

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSlugChange = event => {
    this.setState({
      slug: event.target.value.toLowerCase()
    });
  };

  handleSubmit = (event) => {
    const { center, createTeam } = this.props;

    event.preventDefault();

    createTeam({
      ...center,
      ...this.state
    }).then(() => history.push('/teams'));
  }

  handleSuggestSelect = (suggestion) => {
    this.props.setCenter(suggestion.location);
  }

  render() {
    const { name, slug } = this.state;

    return (
      <div className="page">
        <h2>Create a new team</h2>
        <form onSubmit={this.handleSubmit}>
          <label htmlFor="new-team-name">
            Name:
          </label>
          <input
            id="new-team-name"
            type="text"
            onChange={this.handleChange('name')}
            value={name}
            required
          />
          <label htmlFor="new-team-slug">
            URL: (letters, numbers, and dashes only)
          </label>
          <input
            id="new-team-slug"
            autoCorrect="off"
            autoCapitalize="off"
            type="text"
            value={slug}
            maxLength={63}
            minLength={2}
            pattern={TEAM_SLUG_REGEX}
            onChange={this.handleSlugChange}
            required
          />.lunch.pink
          <label htmlFor="new-team-address">Address:</label>
          <p>
            Pick a centerpoint for your team.
            It will ensure we show nearby recommendations when you search for restaurants.
          </p>
          <TeamMapContainer />
          <Geosuggest
            autoActivateFirstSuggest
            id="new-team-address"
            onActivateSuggest={this.getCoordsForMarker}
            onSuggestSelect={this.handleSuggestSelect}
            placeholder="Enter your address"
            ref={g => { this.geosuggest = g; }}
            types={['geocode']}
          />
          <input type="submit" />
        </form>
      </div>
    );
  }
}

export default NewTeam;
