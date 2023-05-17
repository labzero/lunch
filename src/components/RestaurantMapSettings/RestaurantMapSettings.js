import PropTypes from "prop-types";
import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import s from "./RestaurantMapSettings.scss";

class RestaurantMapSettings extends Component {
  static propTypes = {
    setDefaultZoom: PropTypes.func.isRequired,
    showPOIs: PropTypes.bool.isRequired,
    setShowPOIs: PropTypes.func.isRequired,
    showUnvoted: PropTypes.bool.isRequired,
    setShowUnvoted: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      collapsed: false,
    };
  }

  toggleCollapsed = () =>
    this.setState((prevState) => ({ collapsed: !prevState.collapsed }));

  render() {
    const {
      setDefaultZoom,
      showUnvoted,
      showPOIs,
      setShowPOIs,
      setShowUnvoted,
    } = this.props;

    const { collapsed } = this.state;

    return (
      <div className={s.root}>
        {collapsed ? (
          <Button size="xs" onClick={this.toggleCollapsed} variant="light">
            Show
          </Button>
        ) : (
          <div>
            <div className={s.buttons}>
              <Button size="xs" onClick={setDefaultZoom} variant="light">
                Save zoom level
              </Button>
              <Button size="xs" onClick={this.toggleCollapsed} variant="light">
                Hide
              </Button>
            </div>
            <Form.Check
              checked={showUnvoted}
              className={s.checkbox}
              id="show-unvoted"
              label="Show Unvoted"
              onChange={setShowUnvoted}
            />
            <Form.Check
              checked={showPOIs}
              className={s.checkbox}
              id="show-pois"
              label="Show Points of Interest"
              onChange={setShowPOIs}
            />
          </div>
        )}
      </div>
    );
  }
}

export default withStyles(s)(RestaurantMapSettings);
