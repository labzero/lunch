import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Button from 'react-bootstrap/lib/Button';
import s from './RestaurantMapSettings.scss';

class RestaurantMapSettings extends Component {
  static propTypes = {
    setDefaultZoom: PropTypes.func.isRequired,
    showPOIs: PropTypes.bool.isRequired,
    setShowPOIs: PropTypes.func.isRequired,
    showUnvoted: PropTypes.bool.isRequired,
    setShowUnvoted: PropTypes.func.isRequired
  };

  state = {
    collapsed: false
  }

  toggleCollapsed = () => this.setState({ collapsed: !this.state.collapsed });

  render() {
    const {
      setDefaultZoom,
      showUnvoted,
      showPOIs,
      setShowPOIs,
      setShowUnvoted
    } = this.props;

    const { collapsed } = this.state;

    return (
      <div className={s.root}>
        {collapsed ? (
          <Button bsSize="xsmall" onClick={this.toggleCollapsed}>Show</Button>
        ) : (
          <div>
            <div className={s.buttons}>
              <Button bsSize="xsmall" onClick={setDefaultZoom}>Save zoom level</Button>
              <Button bsSize="xsmall" onClick={this.toggleCollapsed}>Hide</Button>
            </div>
            <div className={`checkbox ${s.checkbox}`}>
              <label htmlFor="show-unvoted">
                <input id="show-unvoted" type="checkbox" checked={showUnvoted} onChange={setShowUnvoted} />
                Show Unvoted
              </label>
            </div>
            <div className={`checkbox ${s.checkbox}`}>
              <label htmlFor="show-pois">
                <input id="show-pois" type="checkbox" checked={showPOIs} onChange={setShowPOIs} />
                Show Points of Interest
              </label>
            </div>
          </div>
        )}
      </div>
    );
  }
}

export default withStyles(s)(RestaurantMapSettings);
