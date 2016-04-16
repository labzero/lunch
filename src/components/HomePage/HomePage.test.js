/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import { _HomePage as HomePage } from './HomePage';
import RestaurantAddFormContainer from '../../containers/RestaurantAddFormContainer';
import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';

describe('HomePage', () => {
  let props;

  beforeEach(() => {
    props = {
      fetchRestaurantsIfNeeded: sinon.mock(),
      invalidateRestaurants: sinon.mock(),
    };
  });

  it('renders form if user is logged in', () => {
    props.user = {
      id: 1
    };

    const wrapper = shallow(<HomePage {...props} />, {
      context: { onSetTitle: () => {} }
    });
    expect(wrapper.find(RestaurantAddFormContainer).length).to.eq(1);
  });
});
