import PropTypes from 'prop-types';
import React, { Component } from 'react';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import InputGroup from 'react-bootstrap/lib/InputGroup';
import OverlayTrigger from 'react-bootstrap/lib/OverlayTrigger';
import Popover from 'react-bootstrap/lib/Popover';
import Row from 'react-bootstrap/lib/Row';
import withStyles from 'isomorphic-style-loader/withStyles';
import TeamGeosuggestContainer from '../TeamGeosuggest/TeamGeosuggestContainer';
import TeamMapContainer from '../TeamMap/TeamMapContainer';
import s from './TeamForm.scss';

class TeamForm extends Component {
  static propTypes = {
    center: PropTypes.object,
    team: PropTypes.object.isRequired,
    updateTeam: PropTypes.func.isRequired,
  };

  static defaultProps = {
    center: undefined,
  };

  constructor(props) {
    super(props);
    this.defaultCenter = {
      lat: props.team.lat,
      lng: props.team.lng,
    };
    this.state = {
      address: props.team.address,
      name: props.team.name,
      sortDuration: props.team.sort_duration,
    };
  }

  handleChange = (field) => (event) => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    const typedsortDuration = typeof this.state.sortDuration === 'number'
      ? this.state.sortDuration
      : parseInt(this.state.sortDuration.slice(), 10);
    if (typedsortDuration > 0) {
      this.props.updateTeam(
        Object.assign({}, this.state, this.props.center, {
          sort_duration: typedsortDuration,
        })
      );
    } else {
      event.stopPropagation();
    }
  };

  render() {
    const { name, address, sortDuration } = this.state;
    const sortDurationAddonLabel = parseInt(sortDuration, 10) === 1 ? 'day' : 'days';
    const popoverRight = (
      <Popover title="Sort Duration" id="sortDuration">
        <p>
          Sort duration refers to the amount of time votes and decisions factor
          in to how restaurants are sorted. For example, if you choose Burger
          Shack for today’s lunch and your sort duration is set to 7 days,
          Burger Shack will appear towards the bottom of your restaurant list
          for the next week.
        </p>
        <p>
          Conversely, if you were to upvote Burger Shack but not choose it for
          today’s lunch, Burger Shack would be prioritized and appear higher in
          your restaurant list for the next week.
        </p>
      </Popover>
    );

    return (
      <form onSubmit={this.handleSubmit}>
        <FormGroup controlId="teamForm-name">
          <ControlLabel>Name</ControlLabel>
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
            initialValue={address}
            onChange={this.handleChange('address')}
          />
        </FormGroup>
        <FormGroup controlId="teamForm-vote-duration">
          <ControlLabel>Sort duration</ControlLabel>
          <OverlayTrigger
            trigger="focus"
            placement="right"
            overlay={popoverRight}
          >
            <Button
              bsSize="xsmall"
              className={[
                'glyphicon glyphicon-question-sign',
                s.overlayTrigger,
              ].join(' ')}
            />
          </OverlayTrigger>
          <Row>
            <Col sm={2}>
              <InputGroup>
                <FormControl
                  type="number"
                  onChange={this.handleChange('sortDuration')}
                  required
                  value={sortDuration}
                  min="1"
                />
                <InputGroup.Addon>{sortDurationAddonLabel}</InputGroup.Addon>
              </InputGroup>
            </Col>
          </Row>
        </FormGroup>
        <Button type="submit">Save Changes</Button>
      </form>
    );
  }
}

export default withStyles(s)(TeamForm);
