jest.unmock('../RestaurantAddTagForm');

import { _RestaurantAddTagForm as RestaurantAddTagForm } from '../RestaurantAddTagForm';
import React from 'react';
import { shallow } from 'enzyme';

describe('RestaurantAddTagForm', () => {
  let props;

  beforeEach(() => {
    props = {
      addNewTagToRestaurant: jest.fn(),
      handleSuggestionSelected: jest.fn(),
      hideAddTagForm: jest.fn(),
      addTagAutosuggestValue: '',
      setAddTagAutosuggestValue: jest.fn(),
      shouldRenderSuggestions: jest.fn(),
      tags: []
    };
  });

  it('disables add button when autosuggest value is blank', () => {
    const wrapper = shallow(<RestaurantAddTagForm {...props} />);
    expect(wrapper.render().find('button').first().attr('disabled')).toBe('disabled');
  });
});
