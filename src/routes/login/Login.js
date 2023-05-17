import React, { Component } from "react";
import PropTypes from "prop-types";
import queryString from "query-string";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import google from "./google.svg";
import s from "./Login.scss";

class Login extends Component {
  static propTypes = {
    host: PropTypes.string.isRequired,
    next: PropTypes.string,
    team: PropTypes.string,
  };

  static defaultProps = {
    next: undefined,
    team: undefined,
  };

  constructor(props) {
    super(props);

    this.state = {
      email: "",
      password: "",
    };
  }

  handleChange = (field) => (event) =>
    this.setState({
      [field]: event.target.value,
    });

  render() {
    const { host, next, team } = this.props;
    const { email, password } = this.state;

    const googleQuery = queryString.stringify({ team, next });
    const nextQuery = queryString.stringify({ next });

    return (
      <div className={s.root}>
        <Container>
          <h2>Log in</h2>
          <div className={s.googleButtonContainer}>
            <Button
              size="lg"
              variant="primary"
              className={s.googleButton}
              href={`//${host}/login/google${
                googleQuery ? `?${googleQuery}` : ""
              }`}
            >
              <img className={s.googleLogo} src={google} alt="" />
              Sign in with Google
            </Button>
          </div>
          <h3>Email/password</h3>
          <form
            action={`/login${nextQuery ? `?${nextQuery}` : ""}`}
            method="post"
          >
            <Row>
              <Col sm={6}>
                <Form.Group className="mb-3" controlId="login-email">
                  <Form.Label>Email</Form.Label>
                  <Form.Control
                    onChange={this.handleChange("email")}
                    name="email"
                    type="email"
                    required
                    value={email}
                  />
                </Form.Group>
                <Form.Group className="mb-3" controlId="login-password">
                  <Form.Label>Password</Form.Label>
                  <Form.Control
                    onChange={this.handleChange("password")}
                    name="password"
                    type="password"
                    required
                    value={password}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Button type="submit">Log in</Button>
            <Button
              href={`//${host}/password/new${email ? `?email=${email}` : ""}`}
              variant="link"
            >
              Forgot password?
            </Button>
          </form>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Login);
