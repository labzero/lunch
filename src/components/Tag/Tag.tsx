import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "./Tag.scss";

export interface TagProps {
  name: string;
  showDelete: boolean;
  onDeleteClicked: () => void;
  exclude?: boolean;
}

const Tag = ({ name, showDelete, onDeleteClicked, exclude }: TagProps) => {
  let deleteButton = null;
  if (showDelete) {
    deleteButton = (
      <button type="button" className={s.button} onClick={onDeleteClicked}>
        &times;
      </button>
    );
  }

  return (
    <div className={`${s.root} ${exclude ? s.exclude : ""}`}>
      {name}
      {deleteButton}
    </div>
  );
};

Tag.defaultProps = {
  exclude: false,
};

export const undecorated = Tag;
export default withStyles(s)(Tag);
