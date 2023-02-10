import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Col from 'react-bootstrap/Col';
import Form from 'react-bootstrap/Form';
import InputGroup from 'react-bootstrap/InputGroup';
import Modal from 'react-bootstrap/Modal';
import ModalBody from 'react-bootstrap/ModalBody';
import ModalFooter from 'react-bootstrap/ModalFooter';
import Row from 'react-bootstrap/Row';
import Button from 'react-bootstrap/Button';
import { TEAM_SLUG_REGEX } from '../../constants';
import s from './ChangeTeamURLModal.scss';

class ChangeTeamURLModal extends Component {
  static propTypes = {
    host: PropTypes.string.isRequired,
    team: PropTypes.object.isRequired,
    shown: PropTypes.bool.isRequired,
    hideModal: PropTypes.func.isRequired,
    updateTeam: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      newSlug: '',
      oldSlug: '',
    };
  }

  handleChange = (field) => (event) => this.setState({
    [field]: event.target.value,
  });

  handleSubmit = () => {
    const { updateTeam, host } = this.props;
    const { newSlug } = this.state;

    updateTeam({ slug: newSlug }).then(() => {
      window.location.href = `//${newSlug}.${host}/team`;
    });
  };

  render() {
    const { team, shown, hideModal } = this.props;
    const { newSlug, oldSlug } = this.state;

    return (
      <Modal show={shown} onHide={hideModal}>
        <ModalBody>
          <p>
            <strong>Be forewarned:</strong>
            {' '}
            Changing the team URL frees up the
            old URL to be used by other teams. This means that any bookmarks
            your team members have created for this team will no longer work.
            We&rsquo;ll send out an email notification to all users on the team
            that this change has taken place.
          </p>
          <p>
            To confirm, please write the current URL of the team in the field
            below.
          </p>
          <Row>
            <Col sm={9}>
              <Form.Group className="mb-3" controlId="changeTeamURLModal-oldSlug">
                <Form.Label>Current team URL</Form.Label>
                <InputGroup>
                  <Form.Control
                    className={s.teamUrl}
                    type="text"
                    onChange={this.handleChange('oldSlug')}
                    pattern={TEAM_SLUG_REGEX}
                    value={oldSlug}
                    required
                  />
                  <InputGroup.Text>.lunch.pink</InputGroup.Text>
                </InputGroup>
              </Form.Group>
              <Form.Group className="mb-3" controlId="changeTeamURLModal-newSlug">
                <Form.Label>New team URL</Form.Label>
                <InputGroup>
                  <Form.Control
                    className={s.teamUrl}
                    type="text"
                    onChange={this.handleChange('newSlug')}
                    pattern={TEAM_SLUG_REGEX}
                    value={newSlug}
                    required
                  />
                  <InputGroup.Text>.lunch.pink</InputGroup.Text>
                </InputGroup>
              </Form.Group>
            </Col>
          </Row>
        </ModalBody>
        <ModalFooter>
          <Button size="sm" onClick={hideModal} variant="light">
            Cancel
          </Button>
          <Button
            autoFocus
            size="sm"
            variant="primary"
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
