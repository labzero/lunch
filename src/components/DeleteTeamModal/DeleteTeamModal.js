import React, { Component, PropTypes } from 'react';
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
import s from './DeleteTeamModal.scss';

class DeleteTeamModal extends Component {
  static propTypes = {
    host: PropTypes.string.isRequired,
    team: PropTypes.object.isRequired,
    shown: PropTypes.bool.isRequired,
    hideModal: PropTypes.func.isRequired,
    deleteTeam: PropTypes.func.isRequired
  };

  state = {
    confirmSlug: ''
  };

  handleChange = (event) => {
    this.setState({
      confirmSlug: event.target.value
    });
  }

  handleSubmit = () => {
    const { deleteTeam, host } = this.props;

    deleteTeam().then(() => {
      window.location.href = `//${host}/teams`;
    });
  }

  render() {
    const { team, shown, hideModal } = this.props;
    const { confirmSlug } = this.state;

    return (
      <Modal show={shown} onHide={hideModal}>
        <ModalBody>
          <p>
            Are you sure you want to delete the {team.name} team?
            {' '}<strong>This is irreversible.</strong>{' '}
            All restaurants and tags will be deleted,
            and all users will be unassigned from the team.
          </p>
          <p>To confirm, please write the URL of the team in the field below.</p>
          <Row>
            <Col sm={9}>
              <FormGroup controlId="deleteTeamModal-confirmSlug">
                <ControlLabel>Team URL</ControlLabel>
                <InputGroup>
                  <FormControl
                    className={s.teamUrl}
                    type="text"
                    onChange={this.handleChange}
                    pattern={TEAM_SLUG_REGEX}
                    value={confirmSlug}
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
            disabled={team.slug !== confirmSlug}
            onClick={this.handleSubmit}
            type="submit"
          >
            Delete
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default withStyles(s)(DeleteTeamModal);
