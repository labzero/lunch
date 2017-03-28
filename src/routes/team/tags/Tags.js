import React, { Component, PropTypes } from 'react';
import TagManagerContainer from '../../../components/TagManager/TagManagerContainer';

class Tags extends Component {
  componentWillMount() {
    this.props.fetchTagsIfNeeded();
  }

  render() {
    return (
      <TagManagerContainer />
    );
  }
}

Tags.propTypes = {
  fetchTagsIfNeeded: PropTypes.func.isRequired
};

export default Tags;
