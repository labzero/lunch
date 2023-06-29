import React, { ChangeEvent, Component, TargetedEvent } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import { User } from "../../../interfaces";
import s from "./Welcome.scss";

interface WelcomeProps {
  updateCurrentUser: (user: Partial<User>) => void;
  user: User;
}

interface WelcomeState {
  name?: string;
}

class Welcome extends Component<WelcomeProps, WelcomeState> {
  constructor(props: WelcomeProps) {
    super(props);

    const { user } = props;

    this.state = {
      name: user.name,
    };
  }

  handleChange = (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    this.setState({ name: event.currentTarget.value });

  handleSubmit = (event: TargetedEvent) => {
    event.preventDefault();
    this.props.updateCurrentUser(this.state);
  };

  render() {
    const { name } = this.state;

    return (
      <div className={s.root}>
        <Container>
          <h2>Welcome!</h2>
          <p>Welcome to Lunch! To continue, please enter your name.</p>
          <form onSubmit={this.handleSubmit}>
            <Row>
              <Col sm={6}>
                <Form.Group className="mb-3" controlId="account-name">
                  <Form.Label>Name</Form.Label>
                  <Form.Control
                    name="name"
                    onChange={this.handleChange}
                    required
                    type="text"
                    value={name}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Button type="submit">Submit</Button>
          </form>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Welcome);
