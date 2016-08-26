/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import DeleteRestaurantModal from './DeleteRestaurantModal';
import { Modal } from 'react-bootstrap';
import { expect } from 'chai';
import React from 'react';
import sinon from 'sinon';
import { shallow } from 'enzyme';

describe('DeleteRestaurantModal', () => {
  let props;

  beforeEach(() => {
    props = {
      restaurantName: 'Food Barn',
      shown: true,
      hideModal: sinon.mock(),
      deleteRestaurant: sinon.mock()
    };
  });

  it('renders confirmation text', () => {
    const wrapper = shallow(
      <DeleteRestaurantModal {...props} />
    );
    expect(wrapper.find(Modal.Body).render().text())
      .to.eq('Are you sure you want to delete Food Barn?');
  });
});
