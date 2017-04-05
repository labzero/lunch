import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import Link from '../../../../components/Link';
import s from './Create.scss';

class Create extends Component {
  static propTypes = {
    success: PropTypes.string.isRequired
  };

  render() {
    const { success } = this.props;

    return (
      <Grid className={s.root}>
        {success === 'sent' && (
          <div>
            <h2>Instructions sent</h2>
            <p>Password reset instructions have been sent to your email address.</p>
          </div>
        )}
        {success === 'reset' && (
          <div>
            <h2>Password reset</h2>
            <p>Your password has been reset. Go ahead and <Link to="/login">log in</Link>.</p>
          </div>
        )}
      </Grid>
    );
  }
}

export default withStyles(s)(Create);
