import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import Loading from '../../../components/Loading';
import TagManagerContainer from '../../../components/TagManager/TagManagerContainer';
import s from './Tags.scss';

class Tags extends Component {
  componentDidMount() {
    this.props.fetchTagsIfNeeded();
  }

  render() {
    if (!this.props.tagListReady) {
      return <Loading />;
    }

    return (
      <Grid className={s.root}>
        <h2>Tags</h2>
        <TagManagerContainer />
      </Grid>
    );
  }
}

Tags.propTypes = {
  fetchTagsIfNeeded: PropTypes.func.isRequired,
  tagListReady: PropTypes.bool.isRequired
};

export default withStyles(s)(Tags);
