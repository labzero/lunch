/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import { _RestaurantAddTagForm as RestaurantAddTagForm } from './RestaurantAddTagForm';
import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';

describe('RestaurantAddTagForm', () => {
  let props;

  beforeEach(() => {
    props = {
      addNewTagToRestaurant: sinon.mock(),
      handleSuggestionSelected: sinon.mock(),
      hideAddTagForm: sinon.mock(),
      autosuggestValue: '',
      setAddTagAutosuggestValue: sinon.mock(),
      tags: []
    };
  });

  it('disables add button when autosuggest value is blank', () => {
    const wrapper = shallow(<RestaurantAddTagForm {...props} />);
    expect(wrapper.render().find('button').first().attr('disabled')).to.eq('disabled');
  });
});
