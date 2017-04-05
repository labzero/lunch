import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import { PASSWORD_MIN_LENGTH } from '../../../../constants';
import s from './Edit.scss';

class Edit extends Component {
  static propTypes = {
    token: PropTypes.string.isRequired
  };

  render() {
    const { token } = this.props;

    return (
      <Grid className={s.root}>
        <h2>Reset password</h2>
        <form action="/password?success=reset" method="post">
          <FormGroup controlId="resetPassword-password">
            <ControlLabel>New password</ControlLabel>
            <FormControl
              minLength={PASSWORD_MIN_LENGTH}
              name="password"
              required
              type="password"
            />
          </FormGroup>
          <input type="hidden" name="token" value={token} />
          <input type="hidden" name="_method" value="PUT" />
          <Button type="submit">Submit</Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(Edit);
