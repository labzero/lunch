jest.unmock('../DeleteRestaurantModal');

import DeleteRestaurantModal from '../DeleteRestaurantModal';
import { Modal } from 'react-bootstrap';
import React from 'react';
import { shallow } from 'enzyme';

describe('DeleteRestaurantModal', () => {
  let props;

  beforeEach(() => {
    props = {
      restaurantName: 'Food Barn',
      shown: true,
      hideModal: jest.fn(),
      deleteRestaurant: jest.fn()
    };
  });

  it('renders confirmation text', () => {
    const wrapper = shallow(
      <DeleteRestaurantModal {...props} />
    );
    expect(wrapper.find(Modal.Body).render().text()).toEqual('Are you sure you want to delete Food Barn?');
  });
});
