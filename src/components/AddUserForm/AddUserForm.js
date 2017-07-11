import PropTypes from 'prop-types';
import React, { Component } from 'react';
import { intlShape } from 'react-intl';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import HelpBlock from 'react-bootstrap/lib/HelpBlock';
import Row from 'react-bootstrap/lib/Row';
import { globalMessageDescriptor as gm } from '../../helpers/generateMessageDescriptor';

class AddUserForm extends Component {
  static propTypes = {
    addUserToTeam: PropTypes.func.isRequired,
    hasGuestRole: PropTypes.bool.isRequired,
    hasMemberRole: PropTypes.bool.isRequired,
    hasOwnerRole: PropTypes.bool.isRequired,
    intl: intlShape.isRequired,
  };

  static defaultState = {
    email: '',
    name: '',
    type: 'member'
  };

  state = Object.assign({}, AddUserForm.defaultState);

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.addUserToTeam(this.state);
    this.setState(Object.assign({}, AddUserForm.defaultState));
  };

  render() {
    const {
      hasGuestRole,
      hasMemberRole,
      hasOwnerRole,
      intl: { formatMessage: f }
    } = this.props;
    const { email, name, type } = this.state;

    return (
      <div>
        <h3>Add User</h3>
        <form onSubmit={this.handleSubmit}>
          <FormGroup controlId="addUserForm-name">
            <ControlLabel>
              Name
            </ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  type="text"
                  onChange={this.handleChange('name')}
                  value={name}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="addUserForm-email">
            <ControlLabel>
              Email
            </ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  type="email"
                  onChange={this.handleChange('email')}
                  value={email}
                  required
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="addUserForm-type">
            <ControlLabel>
              Type
            </ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  componentClass="select"
                  onChange={this.handleChange('type')}
                  value={type}
                  required
                >
                  {hasGuestRole && <option value="guest">{f(gm('guestRole'))}</option>}
                  {hasMemberRole && <option value="member">{f(gm('memberRole'))}</option>}
                  {hasOwnerRole && <option value="owner">{f(gm('ownerRole'))}</option>}
                </FormControl>
              </Col>
            </Row>
            <HelpBlock>
              Members can add new users and remove guests.
              {hasOwnerRole &&
                ' Owners can manage all user roles and manage overall team information.'
              }
            </HelpBlock>
          </FormGroup>
          <Button type="submit">Add</Button>
        </form>
      </div>
    );
  }
}

export default AddUserForm;
