import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Button from 'react-bootstrap/Button';
import RestaurantVoteCountContainer from '../RestaurantVoteCount/RestaurantVoteCountContainer';
import RestaurantVoteButtonContainer from '../RestaurantVoteButton/RestaurantVoteButtonContainer';
import RestaurantDecisionContainer from '../RestaurantDecision/RestaurantDecisionContainer';
import RestaurantTagListContainer from '../RestaurantTagList/RestaurantTagListContainer';
import RestaurantAddTagFormContainer from '../RestaurantAddTagForm/RestaurantAddTagFormContainer';
import RestaurantNameFormContainer from '../RestaurantNameForm/RestaurantNameFormContainer';
import RestaurantDropdownContainer from '../RestaurantDropdown/RestaurantDropdownContainer';
import s from './Restaurant.scss';

class Restaurant extends Component {
  static propTypes = {
    restaurant: PropTypes.object.isRequired,
    loggedIn: PropTypes.bool.isRequired,
    shouldShowAddTagArea: PropTypes.bool,
    shouldShowDropdown: PropTypes.bool,
    listUiItem: PropTypes.object.isRequired,
    showMapAndInfoWindow: PropTypes.func.isRequired,
  };

  static defaultProps = {
    shouldShowAddTagArea: false,
    shouldShowDropdown: false,
  };

  constructor(props) {
    super(props);

    this.state = {
      isAddingTags: false,
    };
  }

  hideAddTagForm = () => {
    this.setState(() => ({
      isAddingTags: false,
    }));
  };

  showAddTagForm = () => {
    this.setState(() => ({
      isAddingTags: true,
    }));
  };

  render() {
    const {
      restaurant,
      shouldShowAddTagArea,
      shouldShowDropdown,
      loggedIn,
      listUiItem,
      showMapAndInfoWindow,
    } = this.props;

    const { isAddingTags } = this.state;

    let voteButton;
    let addTagArea;
    let dropdown;
    if (loggedIn) {
      voteButton = (
        <span className={s.voteButtonContainer}>
          <RestaurantVoteButtonContainer id={restaurant.id} />
        </span>
      );
      if (shouldShowAddTagArea) {
        if (isAddingTags) {
          addTagArea = (
            <RestaurantAddTagFormContainer
              hideAddTagForm={this.hideAddTagForm}
              id={restaurant.id}
            />
          );
        } else {
          addTagArea = (
            <Button
              onClick={this.showAddTagForm}
              size="sm"
              variant="light"
            >
              add tag
            </Button>
          );
        }
      }
      if (shouldShowDropdown) {
        dropdown = (
          <div className={s.dropdownContainer}>
            <RestaurantDropdownContainer id={restaurant.id} />
          </div>
        );
      }
    }

    let nameArea;
    if (listUiItem.isEditingName && shouldShowDropdown) {
      nameArea = (
        <span className={s.restaurantNameFormContainer}>
          <RestaurantNameFormContainer
            id={restaurant.id}
            name={restaurant.name}
          />
        </span>
      );
    } else {
      nameArea = (
        <h2 className={s.heading}>
          <span
            role="button"
            tabIndex={0}
            onClick={showMapAndInfoWindow}
            onKeyPress={showMapAndInfoWindow}
            className={s.headingButton}
          >
            {restaurant.name}
          </span>
          <RestaurantDecisionContainer id={restaurant.id} />
        </h2>
      );
    }

    return (
      <div className={s.root}>
        <div className={s.topRow}>
          <div className={s.data}>
            {nameArea}
            <div className={s.addressContainer}>
              <a
                href={`/api/restaurants/${restaurant.id}/place_url`}
                target="_blank"
                rel="noopener noreferrer"
              >
                {restaurant.address}
              </a>
            </div>
          </div>
          <div className={s.voteContainer}>
            <RestaurantVoteCountContainer id={restaurant.id} />
            {voteButton}
          </div>
        </div>
        <div className={s.footer}>
          <div className={s.tagsArea}>
            <RestaurantTagListContainer id={restaurant.id} />
            {addTagArea}
          </div>
          {dropdown}
        </div>
      </div>
    );
  }
}

export const undecorated = Restaurant;
export default withStyles(s)(Restaurant);
