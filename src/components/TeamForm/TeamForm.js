import PropTypes from 'prop-types';
import React, { Component } from 'react';
import { FaRegQuestionCircle } from 'react-icons/fa';
import Button from 'react-bootstrap/Button';
import Col from 'react-bootstrap/Col';
import Form from 'react-bootstrap/Form';
import InputGroup from 'react-bootstrap/InputGroup';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Popover from 'react-bootstrap/Popover';
import Row from 'react-bootstrap/Row';
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
      <Popover id="sortDuration">
        <Popover.Header>Sort Duration</Popover.Header>
        <Popover.Body>
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
        </Popover.Body>
      </Popover>
    );

    return (
      <form onSubmit={this.handleSubmit}>
        <Form.Group className="mb-3" controlId="teamForm-name">
          <Form.Label>Name</Form.Label>
          <Row>
            <Col sm={6}>
              <Form.Control
                onChange={this.handleChange('name')}
                required
                value={name}
              />
            </Col>
          </Row>
        </Form.Group>
        <Form.Group className="mb-3" controlId="teamForm-address">
          <Form.Label>Address</Form.Label>
          <TeamMapContainer defaultCenter={this.defaultCenter} />
          <TeamGeosuggestContainer
            id="teamForm-address"
            initialValue={address}
            onChange={this.handleChange('address')}
          />
        </Form.Group>
        <Form.Group className="mb-3" controlId="teamForm-vote-duration">
          <Form.Label>Sort duration</Form.Label>
          <OverlayTrigger
            trigger="focus"
            placement="right"
            overlay={popoverRight}
          >
            <Button
              size="xs"
              className={s.overlayTrigger}
              variant="light"
            >
              <FaRegQuestionCircle />
            </Button>
          </OverlayTrigger>
          <Row>
            <Col sm={2}>
              <InputGroup>
                <Form.Control
                  type="number"
                  onChange={this.handleChange('sortDuration')}
                  required
                  value={sortDuration}
                  min="1"
                />
                <InputGroup.Text>{sortDurationAddonLabel}</InputGroup.Text>
              </InputGroup>
            </Col>
          </Row>
        </Form.Group>
        <Button type="submit">Save Changes</Button>
      </form>
    );
  }
}

export default withStyles(s)(TeamForm);
