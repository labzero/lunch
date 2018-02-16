import React, { Component } from 'react';
import PropTypes from 'prop-types';
import queryString from 'query-string';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import Row from 'react-bootstrap/lib/Row';
import google from './google.svg';
import s from './Login.scss';

class Login extends Component {
  static propTypes = {
    host: PropTypes.string.isRequired,
    next: PropTypes.string,
    team: PropTypes.string
  };

  static defaultProps = {
    next: undefined,
    team: undefined
  };

  state = {
    email: '',
    password: ''
  };

  handleChange = field => event =>
    this.setState({
      [field]: event.target.value
    });

  render() {
    const { host, next, team } = this.props;
    const { email, password } = this.state;

    const googleQuery = queryString.stringify({ team, next });
    const nextQuery = queryString.stringify({ next });

    return (
      <div className={s.root}>
        <Grid>
          <h2>Log in</h2>
          <div className={s.googleButtonContainer}>
            <Button
              bsSize="large"
              bsStyle="primary"
              className={s.googleButton}
              href={`//${host}/login/google${googleQuery ? `?${googleQuery}` : ''}`}
            >
              <img className={s.googleLogo} src={google} alt="" />
              Sign in with Google
            </Button>
          </div>
          <h3>Email/password</h3>
          <form action={`/login${nextQuery ? `?${nextQuery}` : ''}`} method="post">
            <Row>
              <Col sm={6}>
                <FormGroup controlId="login-email">
                  <ControlLabel>Email</ControlLabel>
                  <FormControl
                    onChange={this.handleChange('email')}
                    name="email"
                    type="email"
                    required
                    value={email}
                  />
                </FormGroup>
                <FormGroup controlId="login-password">
                  <ControlLabel>Password</ControlLabel>
                  <FormControl
                    onChange={this.handleChange('password')}
                    name="password"
                    type="password"
                    required
                    value={password}
                  />
                </FormGroup>
              </Col>
            </Row>
            <Button type="submit">Log in</Button>
            <Button bsStyle="link" href={`//${host}/password/new${email ? `?email=${email}` : ''}`}>
              Forgot password?
            </Button>
          </form>
        </Grid>
      </div>
    );
  }
}

export default withStyles(s)(Login);
