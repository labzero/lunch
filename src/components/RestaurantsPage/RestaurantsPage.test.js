/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { _RestaurantsPage as RestaurantsPage } from './RestaurantsPage';
import RestaurantAddFormContainer from '../../containers/RestaurantAddFormContainer';

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

    const wrapper = shallow(<RestaurantsPage {...props} />);
    expect(wrapper.find(RestaurantAddFormContainer).length).to.eq(1);
  });
});
