import React, { ChangeEvent, Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import google from "./google.svg";
import s from "./Login.scss";

interface LoginProps {
  host: string;
  next?: string;
  team?: string;
}

interface LoginState {
  email?: string;
  password?: string;
}

class Login extends Component<LoginProps, LoginState> {
  static defaultProps = {
    next: undefined,
    team: undefined,
  };

  constructor(props: LoginProps) {
    super(props);

    this.state = {
      email: "",
      password: "",
    };
  }

  handleChange =
    (field: keyof LoginState) =>
    (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      this.setState({
        [field]: event.currentTarget.value,
      });

  render() {
    const { host, next, team } = this.props;
    const { email, password } = this.state;

    const googleParams: Record<string, string> = {};
    const nextParams: Record<string, string> = {};
    if (team) {
      googleParams.team = team;
    }
    if (next) {
      googleParams.next = next;
      nextParams.next = next;
    }

    const googleQuery = new URLSearchParams(googleParams).toString();
    const nextQuery = new URLSearchParams(nextParams).toString();

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
