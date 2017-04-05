import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import Button from 'react-bootstrap/lib/Button';
import google from './google.svg';
import s from './Login.scss';

class Login extends Component {
  static propTypes = {
    host: PropTypes.string.isRequired,
    teamSlug: PropTypes.string
  };

  static defaultProps = {
    teamSlug: undefined
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
    const { host, teamSlug } = this.props;
    const { email, password } = this.state;

    return (
      <Grid className={s.root}>
        <h2>Log in</h2>
        <div className={s.googleButtonContainer}>
          <Button
            bsSize="large"
            bsStyle="primary"
            className={s.googleButton}
            href={`//${host}/login/google${teamSlug ? `?team=${teamSlug}` : ''}`}
          >
            <img className={s.googleLogo} src={google} alt="" />
            Sign in with Google
          </Button>
        </div>
        <h3>Email/password</h3>
        <form action="/login" method="post">
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
          <Button type="submit">Log in</Button>
          <Button bsStyle="link" href={`//${host}/password/new${email ? `?email=${email}` : ''}`}>
            Forgot password?
          </Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(Login);
