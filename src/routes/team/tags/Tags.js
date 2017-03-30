import React, { Component, PropTypes } from 'react';
import Loading from '../../../components/Loading';
import TagManagerContainer from '../../../components/TagManager/TagManagerContainer';

class Tags extends Component {
  componentDidMount() {
    this.props.fetchTagsIfNeeded();
  }

  render() {
    if (!this.props.tagListReady) {
      return <Loading />;
    }

    return (
      <TagManagerContainer />
    );
  }
}

Tags.propTypes = {
  fetchTagsIfNeeded: PropTypes.func.isRequired,
  tagListReady: PropTypes.bool.isRequired
};

export default Tags;
