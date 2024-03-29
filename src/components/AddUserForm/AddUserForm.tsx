import React, { ChangeEvent, Component, TargetedEvent } from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { RoleType } from "../../interfaces";

interface AddUserFormState {
  email?: string;
  name?: string;
  type?: RoleType;
}

export interface AddUserFormProps {
  addUserToTeam: (state: AddUserFormState) => void;
  hasGuestRole: boolean;
  hasMemberRole: boolean;
  hasOwnerRole: boolean;
}

class AddUserForm extends Component<AddUserFormProps, AddUserFormState> {
  static defaultState: AddUserFormState = {
    email: "",
    name: "",
    type: "member",
  };

  constructor(props: AddUserFormProps) {
    super(props);

    this.state = { ...AddUserForm.defaultState };
  }

  handleChange =
    (field: keyof AddUserFormState) =>
    (
      event: ChangeEvent<
        HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
      >
    ) =>
      this.setState({ [field]: event.currentTarget.value });

  handleSubmit = (event: TargetedEvent) => {
    event.preventDefault();
    this.props.addUserToTeam(this.state);
    this.setState({ ...AddUserForm.defaultState });
  };

  render() {
    const { hasGuestRole, hasMemberRole, hasOwnerRole } = this.props;
    const { email, name, type } = this.state;

    return (
      <div>
        <h3>Add User</h3>
        <form onSubmit={this.handleSubmit}>
          <Form.Group className="mb-3" controlId="addUserForm-name">
            <Form.Label>Name</Form.Label>
            <Row>
              <Col sm={6}>
                <Form.Control
                  type="text"
                  onChange={this.handleChange("name")}
                  value={name}
                />
              </Col>
            </Row>
          </Form.Group>
          <Form.Group className="mb-3" controlId="addUserForm-email">
            <Form.Label>Email</Form.Label>
            <Row>
              <Col sm={6}>
                <Form.Control
                  type="email"
                  onChange={this.handleChange("email")}
                  value={email}
                  required
                />
              </Col>
            </Row>
          </Form.Group>
          <Form.Group className="mb-3" controlId="addUserForm-type">
            <Form.Label>Type</Form.Label>
            <Row>
              <Col sm={6}>
                <Form.Select
                  onChange={this.handleChange("type")}
                  value={type}
                  required
                >
                  {hasGuestRole && <option value="guest">Guest</option>}
                  {hasMemberRole && <option value="member">Member</option>}
                  {hasOwnerRole && <option value="owner">Owner</option>}
                </Form.Select>
              </Col>
            </Row>
            <Form.Text>
              Members can add new users and remove guests.
              {hasOwnerRole &&
                " Owners can manage all user roles and manage overall team information."}
            </Form.Text>
          </Form.Group>
          <Button type="submit">Add</Button>
          <Form.Text>
            Please tell the user you are inviting to check their spam folder if
            they don&rsquo;t receive anything shortly.
          </Form.Text>
        </form>
      </div>
    );
  }
}

export default AddUserForm;
