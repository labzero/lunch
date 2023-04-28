import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Container from 'react-bootstrap/Container';
import s from './Create.scss';

class Create extends Component {
  static propTypes = {
    success: PropTypes.string,
    token: PropTypes.string,
  };

  static defaultProps = {
    success: undefined,
    token: undefined,
  };

  render() {
    const { success, token } = this.props;

    return (
      <div className={s.root}>
        <Container>
          {success === 'sent' && (
            <div>
              <h2>Confirmation sent</h2>
              <p>
                Thanks for requesting an invitation! We&rsquo;ve sent you an
                email &mdash; please follow the provided URL in the email to
                confirm your request. If it doesn&rsquo;t show up, please check
                your spam folder.
              </p>
            </div>
          )}
          {token && (
            <div>
              <h2>Invitation request confirmed</h2>
              <p>
                Thanks for confirming! Sit tight and you should be Lunching it
                up in no time.
              </p>
            </div>
          )}
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Create);
