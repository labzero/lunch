import { TargetedEvent } from "react";
import { connect } from "react-redux";
import {
  addTagFilter,
  clearTagFilters,
  removeTagFilter,
} from "../../actions/tagFilters";
import {
  addTagExclusion,
  clearTagExclusions,
  removeTagExclusion,
} from "../../actions/tagExclusions";
import { setFlipMove } from "../../actions/listUi";
import { Dispatch, State } from "../../interfaces";
import { getRestaurantIds } from "../../selectors/restaurants";
import { getTagFilters } from "../../selectors/tagFilters";
import { getTagExclusions } from "../../selectors/tagExclusions";
import { getTags } from "../../selectors/tags";
import TagFilterForm, { TagFilterFormProps } from "./TagFilterForm";

type OwnProps = Pick<TagFilterFormProps, "exclude">;

const mapStateToProps = (state: State, ownProps: OwnProps) => {
  let addedTags;
  if (ownProps.exclude) {
    addedTags = getTagExclusions(state);
  } else {
    addedTags = getTagFilters(state);
  }
  return {
    ...ownProps,
    allTags: getTags(state),
    addedTags,
    restaurantIds: getRestaurantIds(state),
  };
};

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  setFlipMove: (val: boolean) => dispatch(setFlipMove(val)),
  clearTags() {
    if (ownProps.exclude) {
      dispatch(clearTagExclusions());
    } else {
      dispatch(clearTagFilters());
    }
  },
  addTag(id: number) {
    if (ownProps.exclude) {
      dispatch(addTagExclusion(id));
    } else {
      dispatch(addTagFilter(id));
    }
  },
  removeTag(id: number) {
    if (ownProps.exclude) {
      dispatch(removeTagExclusion(id));
    } else {
      dispatch(removeTagFilter(id));
    }
  },
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>,
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  addByName(autosuggestValue: string) {
    return (event: TargetedEvent<HTMLFormElement>) => {
      event.preventDefault();
      const tag = stateProps.allTags.find((t) => t.name === autosuggestValue);
      if (tag !== undefined) {
        if (ownProps.exclude) {
          dispatchProps.dispatch(addTagExclusion(tag.id));
        } else {
          dispatchProps.dispatch(addTagFilter(tag.id));
        }
      }
    };
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(TagFilterForm);
