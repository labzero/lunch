import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import Col from 'react-bootstrap/lib/Col';
import ControlLabel from 'react-bootstrap/lib/ControlLabel';
import FormControl from 'react-bootstrap/lib/FormControl';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import Grid from 'react-bootstrap/lib/Grid';
import Row from 'react-bootstrap/lib/Row';
import s from './Welcome.scss';

class Welcome extends Component {
  static propTypes = {
    updateCurrentUser: PropTypes.func.isRequired,
    user: PropTypes.object.isRequired
  };

  constructor(props) {
    super(props);

    const { user } = props;

    this.state = {
      name: user.name,
    };
  }

  handleChange = event => this.setState({ name: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.updateCurrentUser(this.state);
  }

  render() {
    const { name } = this.state;

    return (
      <Grid className={s.root}>
        <h2>Welcome!</h2>
        <p>Welcome to Lunch! To continue, please enter your name.</p>
        <form onSubmit={this.handleSubmit}>
          <Row>
            <Col sm={6}>
              <FormGroup controlId="account-name">
                <ControlLabel>Name</ControlLabel>
                <FormControl
                  name="name"
                  onChange={this.handleChange}
                  required
                  type="text"
                  value={name}
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

export default withStyles(s)(Welcome);
