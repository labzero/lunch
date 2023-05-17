import PropTypes from "prop-types";
import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Container from "react-bootstrap/Container";
import Loading from "../../../components/Loading/Loading";
import TagManagerContainer from "../../../components/TagManager/TagManagerContainer";
import s from "./Tags.scss";

class Tags extends Component {
  componentDidMount() {
    this.props.fetchTagsIfNeeded();
  }

  render() {
    if (!this.props.tagListReady) {
      return <Loading />;
    }

    return (
      <div className={s.root}>
        <Container>
          <h2>Tags</h2>
          <TagManagerContainer />
        </Container>
      </div>
    );
  }
}

Tags.propTypes = {
  fetchTagsIfNeeded: PropTypes.func.isRequired,
  tagListReady: PropTypes.bool.isRequired,
};

export default withStyles(s)(Tags);
