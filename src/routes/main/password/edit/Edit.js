import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import Row from 'react-bootstrap/lib/Row';
import { PASSWORD_MIN_LENGTH } from '../../../../constants';
import s from './Edit.scss';

class Edit extends Component {
  static propTypes = {
    token: PropTypes.string.isRequired,
  };

  componentDidMount() {
    this.passwordField.focus();
  }

  render() {
    const { token } = this.props;

    return (
      <div className={s.root}>
        <Grid>
          <h2>Reset password</h2>
          <form action="/password?success=reset" method="post">
            <Row>
              <Col sm={6}>
                <FormGroup controlId="resetPassword-password">
                  <ControlLabel>New password</ControlLabel>
                  <FormControl
                    inputRef={(i) => {
                      this.passwordField = i;
                    }}
                    minLength={PASSWORD_MIN_LENGTH}
                    name="password"
                    required
                    type="password"
                  />
                </FormGroup>
              </Col>
            </Row>
            <input type="hidden" name="token" value={token} />
            <input type="hidden" name="_method" value="PUT" />
            <Button type="submit">Submit</Button>
          </form>
        </Grid>
      </div>
    );
  }
}

export default withStyles(s)(Edit);
