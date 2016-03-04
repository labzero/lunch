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

  render() {
    return (
      <form>
        <Geosuggest
          location={{ lat: () => this.props.latLng.lat, lng: () => this.props.latLng.lng }}
          radius="0"
          onSuggestSelect={this.props.handleSuggestSelect}
          getSuggestLabel={this.props.getSuggestLabel}
        />
      </form>
    );
  }

}

export default withStyles(RestaurantAddForm, s);
