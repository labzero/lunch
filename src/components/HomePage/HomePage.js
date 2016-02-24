import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './HomePage.scss';

const title = 'Lunch';

class HomePage extends Component {

  static contextTypes = {
    onSetTitle: PropTypes.func.isRequired
  };

  componentWillMount() {
    this.context.onSetTitle(title);
  }

  render() {
    return (
      <div>
        <h1>{title}</h1>
        <p>Sorry, but the page you were trying to view does not exist.</p>
      </div>
    );
  }

}

export default withStyles(HomePage, s);
