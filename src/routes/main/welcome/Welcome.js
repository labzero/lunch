import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Button from 'react-bootstrap/Button';
import Col from 'react-bootstrap/Col';
import Form from 'react-bootstrap/Form';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import s from './Welcome.scss';

class Welcome extends Component {
  static propTypes = {
    updateCurrentUser: PropTypes.func.isRequired,
    user: PropTypes.object.isRequired,
  };

  constructor(props) {
    super(props);

    const { user } = props;

    this.state = {
      name: user.name,
    };
  }

  handleChange = (event) => this.setState({ name: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.updateCurrentUser(this.state);
  };

  render() {
    const { name } = this.state;

    return (
      <div className={s.root}>
        <Container>
          <h2>Welcome!</h2>
          <p>Welcome to Lunch! To continue, please enter your name.</p>
          <form onSubmit={this.handleSubmit}>
            <Row>
              <Col sm={6}>
                <Form.Group className="mb-3" controlId="account-name">
                  <Form.Label>Name</Form.Label>
                  <Form.Control
                    name="name"
                    onChange={this.handleChange}
                    required
                    type="text"
                    value={name}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Button type="submit">Submit</Button>
          </form>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Welcome);
