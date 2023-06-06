import React, { Component, RefObject, createRef } from "react";
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

class New extends Component<NewProps> {
  emailField: RefObject<HTMLInputElement>;

  static defaultProps = {
    email: "",
  };

  constructor(props: NewProps) {
    super(props);
    this.emailField = createRef();
  }

  componentDidMount() {
    this.emailField.current?.focus();
  }

  render() {
    const { email } = this.props;

    return (
      <div className={s.root}>
        <Container>
          <h2>New user</h2>
          <form action="/users" method="post">
            <Row>
              <Col sm={6}>
                <Form.Group className="mb-3" controlId="usersNew-name">
                  <Form.Label>Name</Form.Label>
                  <Form.Control name="name" type="text" />
                </Form.Group>
                <Form.Group className="mb-3" controlId="usersNew-email">
                  <Form.Label>Email</Form.Label>
                  <Form.Control
                    defaultValue={email}
                    ref={this.emailField}
                    name="email"
                    required
                    type="email"
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
