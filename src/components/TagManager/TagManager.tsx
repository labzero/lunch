import React from "react";
import TagManagerItemContainer from "../TagManagerItem/TagManagerItemContainer";

export interface TagManagerProps {
  tags: number[];
}

const TagManager = ({ tags }: TagManagerProps) => {
  if (!tags.length) {
    return (
      <p>
        Once you add tags to restaurants, come back to this page and you&#39;ll
        be able to count their uses and remove them!
      </p>
    );
  }

  return (
    <ul>
      {tags.map((id) => (
        <TagManagerItemContainer id={id} key={`tagManagerItem_${id}`} />
      ))}
    </ul>
  );
};

export default TagManager;
