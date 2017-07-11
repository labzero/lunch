import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import HelpBlock from 'react-bootstrap/lib/HelpBlock';
import InputGroup from 'react-bootstrap/lib/InputGroup';
import Row from 'react-bootstrap/lib/Row';
import { TEAM_SLUG_REGEX } from '../../../constants';
import defaultCoords from '../../../constants/defaultCoords';
import TeamGeosuggestContainer from '../../../components/TeamGeosuggest/TeamGeosuggestContainer';
import TeamMapContainer from '../../../components/TeamMap/TeamMapContainer';
import history from '../../../history';
import s from './NewTeam.scss';

class NewTeam extends Component {
  static propTypes = {
    center: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired
    }),
    createTeam: PropTypes.func.isRequired,
  };

  static defaultProps = {
    center: defaultCoords
  }

  state = {
    name: '',
    slug: '',
    address: ''
  };

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

  render() {
    const { name, slug } = this.state;

    return (
      <Grid className={s.root}>
        <h2>Create a new team</h2>
        <form onSubmit={this.handleSubmit}>
          <FormGroup controlId="newTeam-name">
            <ControlLabel>
              Name
            </ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  type="text"
                  onChange={this.handleChange('name')}
                  value={name}
                  required
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="newTeam-slug">
            <ControlLabel>
              URL
            </ControlLabel>
            <Row>
              <Col sm={6}>
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
              </Col>
            </Row>
            <HelpBlock>Letters, numbers, and dashes only.</HelpBlock>
          </FormGroup>
          <FormGroup controlId="newTeam-address">
            <ControlLabel>Address</ControlLabel>
            <p>
              Pick a centerpoint for your team.
              It will ensure that nearby recommendations are shown when you search
              for restaurants.
              You can drag the map or enter your full address.
            </p>
            <TeamMapContainer defaultCenter={defaultCoords} />
            <TeamGeosuggestContainer
              id="newTeam-address"
              initialValue=""
              onChange={this.handleChange('address')}
            />
          </FormGroup>
          <Button type="submit">Submit</Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(NewTeam);
