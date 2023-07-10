import React, { ChangeEvent, Component, RefObject, createRef } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import s from "./New.scss";

interface NewProps {
  email?: string;
}

interface NewState {
  email?: string;
}

class New extends Component<NewProps, NewState> {
  emailField: RefObject<HTMLInputElement>;

  static defaultProps = {
    email: "",
  };

  constructor(props: NewProps) {
    super(props);
    this.emailField = createRef();

    this.state = {
      email: props.email,
    };
  }

  componentDidMount() {
    this.emailField.current?.focus();
  }

  handleChange = (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    this.setState({ email: event.currentTarget.value });

  render() {
    const { email } = this.state;

    return (
      <div className={s.root}>
        <Container>
          <h2>Request an invitation</h2>
          <p>
            Enter your email address and we will send you a link to confirm your
            request.
          </p>
          <form action="/invitation?success=sent" method="post">
            <Row>
              <Col sm={6}>
                <Form.Group className="mb-3" controlId="invitationNew-email">
                  <Form.Label>Email</Form.Label>
                  <Form.Control
                    ref={this.emailField}
                    name="email"
                    onChange={this.handleChange}
                    required
                    type="email"
                    value={email}
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

export default withStyles(s)(New);
