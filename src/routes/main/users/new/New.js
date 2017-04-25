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

  componentDidMount() {
    this.emailField.focus();
  }

  render() {
    const { email } = this.props;

    return (
      <Grid className={s.root}>
        <h2>New user</h2>
        <form action="/users" method="post">
          <FormGroup controlId="usersNew-name">
            <ControlLabel>Name</ControlLabel>
            <FormControl
              name="name"
              type="text"
            />
          </FormGroup>
          <FormGroup controlId="usersNew-email">
            <ControlLabel>Email</ControlLabel>
            <FormControl
              defaultValue={email}
              inputRef={(i) => { this.emailField = i; }}
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
