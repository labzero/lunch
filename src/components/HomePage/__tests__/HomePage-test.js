jest.unmock('../HomePage');

import { _HomePage as HomePage } from '../HomePage';
import RestaurantAddFormContainer from '../../../containers/RestaurantAddFormContainer';
import React from 'react';
import { shallow } from 'enzyme';

describe('HomePage', () => {
  let props;

  beforeEach(() => {
    props = {
      fetchRestaurantsIfNeeded: jest.fn(),
      invalidateRestaurants: jest.fn(),
    };
  });

  it('renders form if user is logged in', () => {
    props.user = {
      id: 1
    };

    const wrapper = shallow(<HomePage {...props} />, {
      context: { onSetTitle: () => {} }
    });
    expect(wrapper.find(RestaurantAddFormContainer).length).toBe(1);
  });
});
