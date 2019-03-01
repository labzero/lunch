import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import InputGroup from 'react-bootstrap/lib/InputGroup';
import Modal from 'react-bootstrap/lib/Modal';
import ModalBody from 'react-bootstrap/lib/ModalBody';
import ModalFooter from 'react-bootstrap/lib/ModalFooter';
import Row from 'react-bootstrap/lib/Row';
import Button from 'react-bootstrap/lib/Button';
import { TEAM_SLUG_REGEX } from '../../constants';
import s from './ChangeTeamURLModal.scss';

class ChangeTeamURLModal extends Component {
  static propTypes = {
    host: PropTypes.string.isRequired,
    team: PropTypes.object.isRequired,
    shown: PropTypes.bool.isRequired,
    hideModal: PropTypes.func.isRequired,
    updateTeam: PropTypes.func.isRequired
  };

  state = {
    newSlug: '',
    oldSlug: ''
  };

  handleChange = field => event => this.setState({
    [field]: event.target.value
  });

  handleSubmit = () => {
    const { updateTeam, host } = this.props;
    const { newSlug } = this.state;

    updateTeam({ slug: newSlug }).then(() => {
      window.location.href = `//${newSlug}.${host}/team`;
    });
  }

  render() {
    const { team, shown, hideModal } = this.props;
    const { newSlug, oldSlug } = this.state;

    return (
      <Modal show={shown} onHide={hideModal}>
        <ModalBody>
          <p>
            <strong>Be forewarned:</strong>
            {' '}
Changing the team URL frees up the old URL to be used
            by other teams. This means that any bookmarks your team members have created for this
            team will no longer work. We&rsquo;ll send out an email notification to all users on
            the team that this change has taken place.
          </p>
          <p>To confirm, please write the current URL of the team in the field below.</p>
          <Row>
            <Col sm={9}>
              <FormGroup controlId="changeTeamURLModal-oldSlug">
                <ControlLabel>Current team URL</ControlLabel>
                <InputGroup>
                  <FormControl
                    className={s.teamUrl}
                    type="text"
                    onChange={this.handleChange('oldSlug')}
                    pattern={TEAM_SLUG_REGEX}
                    value={oldSlug}
                    required
                  />
                  <InputGroup.Addon>.lunch.pink</InputGroup.Addon>
                </InputGroup>
              </FormGroup>
              <FormGroup controlId="changeTeamURLModal-newSlug">
                <ControlLabel>New team URL</ControlLabel>
                <InputGroup>
                  <FormControl
                    className={s.teamUrl}
                    type="text"
                    onChange={this.handleChange('newSlug')}
                    pattern={TEAM_SLUG_REGEX}
                    value={newSlug}
                    required
                  />
                  <InputGroup.Addon>.lunch.pink</InputGroup.Addon>
                </InputGroup>
              </FormGroup>
            </Col>
          </Row>
        </ModalBody>
        <ModalFooter>
          <Button type="button" bsSize="small" onClick={hideModal}>Cancel</Button>
          <Button
            autoFocus
            bsSize="small"
            bsStyle="primary"
            disabled={team.slug !== oldSlug}
            onClick={this.handleSubmit}
            type="submit"
          >
            Change
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default withStyles(s)(ChangeTeamURLModal);
