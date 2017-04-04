import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import Button from 'react-bootstrap/lib/Button';
import google from './google.svg';
import s from './Login.scss';

const Login = () => (
  <Grid className={s.root}>
    <h2>Log in</h2>
    <div className={s.googleButtonContainer}>
      <Button
        bsSize="large"
        bsStyle="primary"
        className={s.googleButton}
        href="/login/google"
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
          name="email"
          type="email"
          required
        />
      </FormGroup>
      <FormGroup controlId="login-password">
        <ControlLabel>Password</ControlLabel>
        <FormControl
          name="password"
          type="password"
          required
        />
      </FormGroup>
      <Button type="submit">Log in</Button>
    </form>
  </Grid>
);

export default withStyles(s)(Login);
