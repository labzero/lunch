import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Container from "react-bootstrap/Container";
import Loading from "../../../components/Loading/Loading";
import TagManagerContainer from "../../../components/TagManager/TagManagerContainer";
import s from "./Tags.scss";

interface TagsProps {
  fetchTagsIfNeeded: () => void;
  tagListReady: boolean;
}

class Tags extends Component<TagsProps> {
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

export default withStyles(s)(Tags);
