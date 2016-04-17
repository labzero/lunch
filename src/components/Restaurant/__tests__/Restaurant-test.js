jest.unmock('../Restaurant');

import { _Restaurant as Restaurant } from '../Restaurant';
import RestaurantAddTagFormContainer from '../../../containers/RestaurantAddTagFormContainer';
import React from 'react';
import { shallow } from 'enzyme';

describe('Restaurant', () => {
  let props;

  beforeEach(() => {
    props = {
      restaurant: {
        tags: []
      },
      shouldShowAddTagArea: true,
      shouldShowDropdown: true,
      user: {
        id: 1
      },
      listUiItem: {},
      showAddTagForm: jest.fn(),
      showMapAndInfoWindow: jest.fn(),
      removeTag: jest.fn()
    };
  });

  it('renders add tag form when user is adding tags', () => {
    const wrapper = shallow(<Restaurant {...props} />);
    expect(wrapper.find(RestaurantAddTagFormContainer).length).toBe(0);
    wrapper.setProps({ listUiItem: { isAddingTags: true } });
    expect(wrapper.find(RestaurantAddTagFormContainer).length).toBe(1);
  });
});
