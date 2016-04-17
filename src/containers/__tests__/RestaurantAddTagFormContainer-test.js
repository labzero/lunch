jest.unmock('../RestaurantAddTagFormContainer');
jest.unmock('../../helpers/TagAutosuggestHelper');
jest.unmock('../../schemas');
jest.unmock('react-redux');
jest.unmock('redux');
jest.unmock('normalizr');

import RestaurantAddTagFormContainer from '../RestaurantAddTagFormContainer';
import RestaurantAddTagForm from '../../components/RestaurantAddTagForm';
import * as schemas from '../../schemas';
import React from 'react';
import { shallow } from 'enzyme';
import { normalize, arrayOf } from 'normalizr';
import { createStore } from 'redux';
import { makeGetTagList } from '../../selectors';
import { getRestaurantById } from '../../selectors/restaurants';
import { getListUiItemForId } from '../../selectors/listUi';

describe('RestaurantAddTagFormContainer', () => {
  let state;
  let store;
  let props;
  let restaurant;

  beforeEach(() => {
    state = {};
    store = createStore(() => state, state);
    restaurant = {
      id: 1,
      tags: []
    };
    makeGetTagList.mockImplementation(() => () => [{
      id: 1,
      name: 'take out'
    }, {
      id: 2,
      name: 'friday'
    }, {
      id: 3,
      name: 'gross'
    }, {
      id: 4,
      name: 'mexican'
    }, {
      id: 5,
      name: 'italian'
    }, {
      id: 6,
      name: 'sandwiches'
    }, {
      id: 7,
      name: 'ramen'
    }, {
      id: 8,
      name: 'truck'
    }, {
      id: 9,
      name: 'expensive'
    }, {
      id: 10,
      name: 'touristy'
    }, {
      id: 11,
      name: 'chain'
    }]);
    getListUiItemForId.mockImplementation(() => ({}));
    props = {
      id: 1
    };
  });

  it('returns up to 10 tags', () => {
    getRestaurantById.mockImplementation(() => normalize([restaurant], arrayOf(schemas.restaurant)));
    const wrapper = shallow(<RestaurantAddTagFormContainer {...props} />, { context: { store } });
    expect(wrapper.find(RestaurantAddTagForm).first().props().tags.length).toBe(10);
  });

  it('omits added tags', () => {
    restaurant.tags = [1, 2, 3, 4, 5];
    getRestaurantById.mockImplementation(() => normalize([restaurant], arrayOf(schemas.restaurant)));
    const wrapper = shallow(<RestaurantAddTagFormContainer {...props} />, { context: { store } });
    expect(wrapper.find(RestaurantAddTagForm).first().props().tags.length).toBe(6);
  });

  it('filters by query and added tags', () => {
    restaurant.tags = [4];
    getRestaurantById.mockImplementation(() => normalize([restaurant], arrayOf(schemas.restaurant)));
    getListUiItemForId.mockImplementation(() => ({ addTagAutosuggestValue: 'x' }));
    const wrapper = shallow(<RestaurantAddTagFormContainer {...props} />, { context: { store } });
    expect(wrapper.find(RestaurantAddTagForm).first().props().tags.length).toBe(1);
  });
});
