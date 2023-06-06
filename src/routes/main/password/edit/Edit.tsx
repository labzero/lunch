import React, { Component, RefObject, createRef } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import { PASSWORD_MIN_LENGTH } from "../../../../constants";
import s from "./Edit.scss";

interface EditProps {
  token: string;
}

class Edit extends Component<EditProps> {
  passwordField: RefObject<HTMLInputElement>;

  constructor(props: EditProps) {
    super(props);
    this.passwordField = createRef();
  }

  componentDidMount() {
    this.passwordField.current?.focus();
  }

  render() {
    const { token } = this.props;

    return (
      <div className={s.root}>
        <Container>
          <h2>Reset password</h2>
          <form action="/password?success=reset" method="post">
            <Row>
              <Col sm={6}>
                <Form.Group className="mb-3" controlId="resetPassword-password">
                  <Form.Label>New password</Form.Label>
                  <Form.Control
                    ref={this.passwordField}
                    minLength={PASSWORD_MIN_LENGTH}
                    name="password"
                    required
                    type="password"
                  />
                </Form.Group>
              </Col>
            </Row>
            <input type="hidden" name="token" value={token} />
            <input type="hidden" name="_method" value="PUT" />
            <Button type="submit">Submit</Button>
          </form>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Edit);
