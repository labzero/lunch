jest.unmock('../ModalSection');

import ModalSection from '../ModalSection';
import DeleteRestaurantModalContainer from '../../../containers/DeleteRestaurantModalContainer';
import React from 'react';
import { shallow } from 'enzyme';

const context = { insertCss: () => {} };

describe('ModalSection', () => {
  let props;

  beforeEach(() => {
    props = {
      modals: {}
    };
    window.ReconnectingWebSocket = jest.fn();
  });

  it('adds a modal if there is data', () => {
    props.modals.deleteRestaurant = { name: 'Food Barn' };
    const wrapper = shallow(
      <ModalSection {...props}><div /></ModalSection>,
    { context });
    expect(wrapper.find(DeleteRestaurantModalContainer).length).toBe(1);
  });
});
