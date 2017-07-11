import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import HelpBlock from 'react-bootstrap/lib/HelpBlock';
import Row from 'react-bootstrap/lib/Row';
import { PASSWORD_MIN_LENGTH } from '../../../constants';
import s from './Account.scss';

class Account extends Component {
  static propTypes = {
    updateCurrentUser: PropTypes.func.isRequired,
    user: PropTypes.object.isRequired
  };

  constructor(props) {
    super(props);

    const { user } = props;

    this.state = {
      name: user.name,
      email: user.email,
      password: ''
    };
  }

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.updateCurrentUser(this.state).then(() => {
      this.setState({
        password: ''
      });
    }).catch(() => {});
  }

  render() {
    const { name, email, password } = this.state;

    return (
      <Grid className={s.root}>
        <h2>Account</h2>
        <form onSubmit={this.handleSubmit}>
          <FormGroup controlId="account-name">
            <ControlLabel>Name</ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  name="name"
                  onChange={this.handleChange('name')}
                  required
                  type="text"
                  value={name}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="account-name">
            <ControlLabel>Email</ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  name="email"
                  onChange={this.handleChange('email')}
                  required
                  type="email"
                  value={email}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="account-name">
            <ControlLabel>Change password?</ControlLabel>
            <Row>
              <Col sm={6}>
                <FormControl
                  minLength={PASSWORD_MIN_LENGTH}
                  name="password"
                  onChange={this.handleChange('password')}
                  type="password"
                  value={password}
                />
              </Col>
            </Row>
            <HelpBlock>Leave this blank if you don&rsquo;t want to set a new password.</HelpBlock>
          </FormGroup>
          <Button type="submit">Submit</Button>
        </form>
      </Grid>
    );
  }
}

export default withStyles(s)(Account);
