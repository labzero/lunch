import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import s from './New.scss';

class New extends Component {
  static propTypes = {
    email: PropTypes.string
  };

  static defaultProps = {
    email: ''
  };

  render() {
    const { email } = this.props;

    return (
      <Grid className={s.root}>
        <h2>Request password reset</h2>
        <p>
          Enter your email address and we will send you a link
          to reset your password.
        </p>
        <form action="/password?success=sent" method="post">
          <FormGroup controlId="resetPassword-email">
            <ControlLabel>Email</ControlLabel>
            <FormControl
              defaultValue={email}
              name="email"
              required
              type="email"
            />
          </FormGroup>
          <Button type="submit">Submit</Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(New);
