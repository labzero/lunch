import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import HelpBlock from 'react-bootstrap/lib/HelpBlock';
import InputGroup from 'react-bootstrap/lib/InputGroup';
import Geosuggest from 'react-geosuggest';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import { TEAM_SLUG_REGEX } from '../../../constants';
import defaultCoords from '../../../constants/defaultCoords';
import TeamMapContainer from '../../../components/TeamMap/TeamMapContainer';
import history from '../../../core/history';
import s from './NewTeam.scss';

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
    center: defaultCoords
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
      <Grid className={s.root}>
        <h2>Create a new team</h2>
        <form onSubmit={this.handleSubmit}>
          <FormGroup controlId="new-team-name">
            <ControlLabel>
              Name
            </ControlLabel>
            <FormControl
              type="text"
              onChange={this.handleChange('name')}
              value={name}
              required
            />
          </FormGroup>
          <FormGroup controlId="new-team-slug">
            <ControlLabel>
              URL
            </ControlLabel>
            <InputGroup>
              <FormControl
                autoCorrect="off"
                autoCapitalize="off"
                className={s.teamUrl}
                type="text"
                value={slug}
                maxLength={63}
                minLength={2}
                pattern={TEAM_SLUG_REGEX}
                onChange={this.handleSlugChange}
                required
              />
              <InputGroup.Addon>.lunch.pink</InputGroup.Addon>
            </InputGroup>
            <HelpBlock>Letters, numbers, and dashes only.</HelpBlock>
          </FormGroup>
          <FormGroup controlId="new-team-address">
            <ControlLabel>Address</ControlLabel>
            <p>
              Pick a centerpoint for your team.
              It will ensure that nearby recommendations are shown when you search
              for restaurants.
              You can drag the map or enter your full address.
            </p>
            <TeamMapContainer />
            <Geosuggest
              autoActivateFirstSuggest
              id="new-team-address"
              inputClassName="form-control"
              onActivateSuggest={this.getCoordsForMarker}
              onSuggestSelect={this.handleSuggestSelect}
              placeholder="Enter your address"
              ref={g => { this.geosuggest = g; }}
              types={['geocode']}
            />
          </FormGroup>
          <Button type="submit">Submit</Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(NewTeam);
