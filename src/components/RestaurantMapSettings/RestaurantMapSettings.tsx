import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button, { ButtonPropsWithXsSize } from "react-bootstrap/Button";
import { BsPrefixRefForwardingComponent } from "react-bootstrap/esm/helpers";
import Form from "react-bootstrap/Form";
import s from "./RestaurantMapSettings.scss";

const ButtonWithCustomProps = Button as BsPrefixRefForwardingComponent<
  "button",
  ButtonPropsWithXsSize
>;

interface RestaurantMapSettingsProps {
  setDefaultZoom: () => void;
  showPOIs: boolean;
  setShowPOIs: () => void;
  showUnvoted: boolean;
  setShowUnvoted: () => void;
}

interface RestaurantMapSettingsState {
  collapsed: boolean;
}

class RestaurantMapSettings extends Component<
  RestaurantMapSettingsProps,
  RestaurantMapSettingsState
> {
  constructor(props: RestaurantMapSettingsProps) {
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
          <ButtonWithCustomProps
            size="xs"
            onClick={this.toggleCollapsed}
            variant="light"
          >
            Show
          </ButtonWithCustomProps>
        ) : (
          <div>
            <div className={s.buttons}>
              <ButtonWithCustomProps
                size="xs"
                onClick={setDefaultZoom}
                variant="light"
              >
                Save zoom level
              </ButtonWithCustomProps>
              <ButtonWithCustomProps
                size="xs"
                onClick={this.toggleCollapsed}
                variant="light"
              >
                Hide
              </ButtonWithCustomProps>
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
