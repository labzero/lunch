/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import { _Restaurant as Restaurant } from './Restaurant';
import RestaurantAddTagFormContainer from '../../containers/RestaurantAddTagFormContainer';
import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
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
      showAddTagForm: sinon.mock(),
      showMapAndInfoWindow: sinon.mock(),
      removeTag: sinon.mock()
    };
  });

  it('renders add tag form when user is adding tags', () => {
    const wrapper = shallow(<Restaurant {...props} />);
    expect(wrapper.find(RestaurantAddTagFormContainer).length).to.eq(0);
    wrapper.setProps({ listUiItem: { isAddingTags: true } });
    expect(wrapper.find(RestaurantAddTagFormContainer).length).to.eq(1);
  });
});
