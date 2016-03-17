jest.unmock('../DeleteRestaurantModal');

import DeleteRestaurantModal from '../DeleteRestaurantModal';
import { Modal } from 'react-bootstrap';
import React from 'react';
import { shallow } from 'enzyme';

describe('DeleteRestaurantModal', () => {
  let hideModal;
  let deleteRestaurant;
  let restaurant;

  beforeEach(() => {
    hideModal = jest.fn();
    deleteRestaurant = jest.fn();
  });

  it('renders confirmation text', () => {
    restaurant = {
      name: 'Food Barn'
    };

    const wrapper = shallow(
      <DeleteRestaurantModal restaurant={restaurant} shown hideModal={hideModal} deleteRestaurant={deleteRestaurant} />
    );
    expect(wrapper.find(Modal.Body).render().text()).toEqual('Are you sure you want to delete Food Barn?');
  });

  it('keeps restaurant name upon restaurant deletion', () => {
    restaurant = {
      name: 'Food Barn'
    };

    const wrapper = shallow(
      <DeleteRestaurantModal restaurant={restaurant} shown hideModal={hideModal} deleteRestaurant={deleteRestaurant} />
    );
    wrapper.setProps({ restaurant: {} });
    expect(wrapper.find(Modal.Body).render().text()).toEqual('Are you sure you want to delete Food Barn?');
  });
});
