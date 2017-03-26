import React, { Component, PropTypes } from 'react';
import TagManagerContainer from '../../../../components/TagManager/TagManagerContainer';

class Tags extends Component {
  componentWillMount() {
    this.props.fetchTagsIfNeeded();
  }

  render() {
    const { teamSlug } = this.props;
    return (
      <TagManagerContainer teamSlug={teamSlug} />
    );
  }
}

Tags.propTypes = {
  fetchTagsIfNeeded: PropTypes.func.isRequired,
  teamSlug: PropTypes.string.isRequired
};

export default Tags;
