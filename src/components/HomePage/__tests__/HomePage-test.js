jest.unmock('../HomePage');

import { _HomePage as HomePage } from '../HomePage';
import RestaurantAddFormContainer from '../../../containers/RestaurantAddFormContainer';
import React from 'react';
import { shallow } from 'enzyme';

describe('HomePage', () => {
  let fetchRestaurantsIfNeeded;
  let user;

  beforeEach(() => {
    fetchRestaurantsIfNeeded = jest.fn();
  });

  it('renders form if user is logged in', () => {
    user = {
      id: 1
    };

    const wrapper = shallow(<HomePage user={user} fetchRestaurantsIfNeeded={fetchRestaurantsIfNeeded} />, {
      context: { onSetTitle: () => {} }
    });
    expect(wrapper.find(RestaurantAddFormContainer).length).toBe(1);
  });
});
