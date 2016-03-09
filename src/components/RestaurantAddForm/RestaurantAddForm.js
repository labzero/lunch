import React, { Component, PropTypes } from 'react';
import Geosuggest from 'react-geosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddForm.scss';

class RestaurantAddForm extends Component {

  static propTypes = {
    getSuggestLabel: PropTypes.func.isRequired,
    handleSuggestSelect: PropTypes.func.isRequired,
    latLng: PropTypes.object.isRequired
  }

  static contextTypes = {
    insertCss: PropTypes.func,
  }

  componentWillMount() {
    this.removeCss = this.context.insertCss(s);
  }

  componentWillUnmount() {
    this.removeCss();
  }

  handleSuggestSelect(suggestion) {
    this.props.handleSuggestSelect(suggestion, this._geosuggest);
  }

  render() {
    const boundHandleSuggestSelect = this.handleSuggestSelect.bind(this);

    return (
      <form>
        <Geosuggest
          location={{ lat: () => this.props.latLng.lat, lng: () => this.props.latLng.lng }}
          radius="0"
          onSuggestSelect={boundHandleSuggestSelect}
          getSuggestLabel={this.props.getSuggestLabel}
          ref={g => { this._geosuggest = g; } }
        />
      </form>
    );
  }

}

export default withStyles(RestaurantAddForm, s);
