import PropTypes from 'prop-types';
import React, { Component } from 'react';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Row from 'react-bootstrap/lib/Row';
import TeamGeosuggestContainer from '../TeamGeosuggest/TeamGeosuggestContainer';
import TeamMapContainer from '../TeamMap/TeamMapContainer';

class TeamForm extends Component {
  static propTypes = {
    center: PropTypes.object,
    team: PropTypes.object.isRequired,
    updateTeam: PropTypes.func.isRequired
  };

  static defaultProps = {
    center: undefined
  };

  constructor(props) {
    super(props);
    this.defaultCenter = {
      lat: props.team.lat,
      lng: props.team.lng
    };
    this.state = {
      address: props.team.address,
      name: props.team.name
    };
  }

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.updateTeam(Object.assign({}, this.state, this.props.center));
  };

  render() {
    const { team } = this.props;
    const { name } = this.state;

    return (
      <form onSubmit={this.handleSubmit}>
        <FormGroup controlId="teamForm-name">
          <ControlLabel>
            Name
          </ControlLabel>
          <Row>
            <Col sm={6}>
              <FormControl
                onChange={this.handleChange('name')}
                required
                value={name}
              />
            </Col>
          </Row>
        </FormGroup>
        <FormGroup controlId="teamForm-address">
          <ControlLabel>Address</ControlLabel>
          <TeamMapContainer defaultCenter={this.defaultCenter} />
          <TeamGeosuggestContainer
            id="teamForm-address"
            initialValue={team.address}
            onChange={this.handleChange('address')}
          />
        </FormGroup>
        <Button type="submit">Save Changes</Button>
      </form>
    );
  }
}

export default TeamForm;
