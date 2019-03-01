/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { _RestaurantAddTagForm as RestaurantAddTagForm } from './RestaurantAddTagForm';

describe('RestaurantAddTagForm', () => {
  let props;

  beforeEach(() => {
    props = {
      addedTags: [],
      addNewTagToRestaurant: sinon.mock(),
      addTagToRestaurant: () => {},
      hideAddTagForm: () => {},
      tags: []
    };
  });

  it('disables add button when autosuggest value is blank', () => {
    const wrapper = shallow(<RestaurantAddTagForm {...props} />, { disableLifecycleMethods: true });
    expect(wrapper.render().find('button').first()
      .attr('disabled')).to.eq('disabled');
  });
});
