/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import ModalSection from './ModalSection';
import DeleteRestaurantModalContainer from '../../containers/DeleteRestaurantModalContainer';
import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';

const context = { insertCss: () => {} };

describe('ModalSection', () => {
  let props;

  beforeEach(() => {
    props = {
      modals: {}
    };
  });

  it('adds a modal if there is data', () => {
    props.modals.deleteRestaurant = { name: 'Food Barn' };
    const wrapper = shallow(
      <ModalSection {...props}><div /></ModalSection>,
    { context });
    expect(wrapper.find(DeleteRestaurantModalContainer).length).to.eq(1);
  });
});
