import PropTypes from "prop-types";
import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Container from "react-bootstrap/Container";
import Link from "../../../../components/Link";
import s from "./Create.scss";

class Create extends Component {
  static propTypes = {
    success: PropTypes.string.isRequired,
  };

  render() {
    const { success } = this.props;

    return (
      <div className={s.root}>
        <Container>
          {success === "sent" && (
            <div>
              <h2>Instructions sent</h2>
              <p>
                Password reset instructions have been sent to your email
                address.
              </p>
            </div>
          )}
          {success === "reset" && (
            <div>
              <h2>Password reset</h2>
              <p>
                Your password has been reset. Go ahead and
                <Link to="/login">log in</Link>.
              </p>
            </div>
          )}
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Create);
