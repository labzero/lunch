import React, { ChangeEvent, Component, FormEvent } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import { PASSWORD_MIN_LENGTH } from "../../../constants";
import { Action, User } from "../../../interfaces";
import s from "./Account.scss";

interface AccountProps {
  updateCurrentUser: (user: Partial<User>) => Promise<Action>;
  user: User;
}

interface AccountState {
  name?: string;
  email?: string;
  password?: string;
}

class Account extends Component<AccountProps, AccountState> {
  constructor(props: AccountProps) {
    super(props);

    const { user } = props;

    this.state = {
      name: user.name,
      email: user.email,
      password: "",
    };
  }

  handleChange =
    (field: keyof AccountState) => (event: ChangeEvent<HTMLInputElement>) =>
      this.setState({ [field]: event.target.value });

  handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    this.props
      .updateCurrentUser(this.state)
      .then(() => {
        this.setState({
          password: "",
        });
      })
      .catch(() => undefined);
  };

  render() {
    const { name, email, password } = this.state;

    return (
      <div className={s.root}>
        <Container>
          <h2>Account</h2>
          <form onSubmit={this.handleSubmit}>
            <Form.Group className="mb-3" controlId="account-name">
              <Form.Label>Name</Form.Label>
              <Row>
                <Col sm={6}>
                  <Form.Control
                    name="name"
                    onChange={this.handleChange("name")}
                    required
                    type="text"
                    value={name}
                  />
                </Col>
              </Row>
            </Form.Group>
            <Form.Group className="mb-3" controlId="account-email">
              <Form.Label>Email</Form.Label>
              <Row>
                <Col sm={6}>
                  <Form.Control
                    name="email"
                    onChange={this.handleChange("email")}
                    required
                    type="email"
                    value={email}
                  />
                </Col>
              </Row>
            </Form.Group>
            <Form.Group className="mb-3" controlId="account-password">
              <Form.Label>Change password?</Form.Label>
              <Row>
                <Col sm={6}>
                  <Form.Control
                    minLength={PASSWORD_MIN_LENGTH}
                    name="password"
                    onChange={this.handleChange("password")}
                    type="password"
                    value={password}
                  />
                </Col>
              </Row>
              <Form.Text>
                Leave this blank if you don&rsquo;t want to set a new password.
              </Form.Text>
            </Form.Group>
            <Button type="submit">Submit</Button>
          </form>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Account);
