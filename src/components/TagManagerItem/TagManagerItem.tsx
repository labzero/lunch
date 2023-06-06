import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import { Tag } from "../../interfaces";
import TagContainer from "../Tag/TagContainer";
import s from "./TagManagerItem.scss";

interface TagManagerItemProps {
  tag: Tag;
  showDelete: boolean;
  handleDeleteClicked: () => void;
}

const TagManagerItem = ({
  tag,
  showDelete,
  handleDeleteClicked,
}: TagManagerItemProps) => (
  <li>
    <span className={s.tagContainer}>
      <TagContainer
        id={tag.id}
        showDelete={showDelete}
        onDeleteClicked={handleDeleteClicked}
      />
    </span>
    ({tag.restaurant_count})
  </li>
);

export default withStyles(s)(TagManagerItem);
