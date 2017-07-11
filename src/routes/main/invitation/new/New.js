import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import Row from 'react-bootstrap/lib/Row';
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
        <h2>Request an invitation</h2>
        <p>
          Enter your email address and we will send you a link
          to confirm your request.
        </p>
        <form action="/invitation?success=sent" method="post">
          <Row>
            <Col sm={6}>
              <FormGroup controlId="invitationNew-email">
                <ControlLabel>Email</ControlLabel>
                <FormControl
                  defaultValue={email}
                  inputRef={(i) => { this.emailField = i; }}
                  name="email"
                  required
                  type="email"
                />
              </FormGroup>
            </Col>
          </Row>
          <Button type="submit">Submit</Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(New);
