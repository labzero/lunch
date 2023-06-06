import { connect } from "react-redux";
import { State } from "../../interfaces";
import { getTagById } from "../../selectors/tags";
import Tag, { TagProps } from "./Tag";

interface OwnProps extends Omit<TagProps, "name"> {
  id: number;
  name?: string;
}

const mapStateToProps = () => {
  let name: string;
  return (state: State, ownProps: OwnProps) => {
    if (ownProps.name === undefined) {
      const tag = getTagById(state, ownProps.id);
      if (tag !== undefined) {
        name = tag.name;
      }
    } else {
      name = ownProps.name;
    }
    return {
      name,
      exclude: ownProps.exclude,
    };
  };
};

export default connect(mapStateToProps)(Tag);
