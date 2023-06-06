import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "./RestaurantTagList.scss";
import TagContainer from "../Tag/TagContainer";

interface RestaurantTagListProps {
  ids: number[];
  removeTag: (tagId: number) => void;
  loggedIn: boolean;
}

const RestaurantTagList = ({
  ids,
  removeTag,
  loggedIn,
}: RestaurantTagListProps) => (
  <ul className={`${s.root} ${ids.length === 0 ? s.empty : ""}`}>
    {ids.map((tagId) => {
      const boundRemoveTag = () => {
        removeTag(tagId);
      };
      return (
        <li className={s.tagItem} key={`restaurantTag_${tagId}`}>
          <TagContainer
            id={tagId}
            showDelete={loggedIn}
            onDeleteClicked={boundRemoveTag}
          />
        </li>
      );
    })}
  </ul>
);

export default withStyles(s)(RestaurantTagList);
