jest.unmock('../RestaurantAddTagFormContainer');
jest.unmock('react-redux');
jest.unmock('redux');

import RestaurantAddTagFormContainer from '../RestaurantAddTagFormContainer';
import RestaurantAddTagForm from '../../components/RestaurantAddTagForm';
import React from 'react';
import { shallow } from 'enzyme';
import { createStore } from 'redux';

describe('RestaurantAddTagFormContainer', () => {
  let state;
  let props;

  beforeEach(() => {
    state = {
      listUi: {},
      restaurants: {
        items: [{
          id: 1,
          tags: []
        }]
      },
      tags: {
        items: [{
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
        }]
      }
    };
    props = {
      id: 1
    };
  });

  it('returns up to 10 tags', () => {
    const store = createStore(() => state, state);
    const wrapper = shallow(<RestaurantAddTagFormContainer {...props} />, { context: { store } });
    expect(wrapper.find(RestaurantAddTagForm).first().props().tags.length).toBe(10);
  });

  it('omits added tags', () => {
    state.restaurants.items[0].tags = [1, 2, 3, 4, 5];
    const store = createStore(() => state, state);
    const wrapper = shallow(<RestaurantAddTagFormContainer {...props} />, { context: { store } });
    expect(wrapper.find(RestaurantAddTagForm).first().props().tags.length).toBe(6);
  });

  it('filters by query and added tags', () => {
    state.restaurants.items[0].tags = [4];
    state.listUi[1] = { addTagAutosuggestValue: 'x' };
    const store = createStore(() => state, state);
    const wrapper = shallow(<RestaurantAddTagFormContainer {...props} />, { context: { store } });
    expect(wrapper.find(RestaurantAddTagForm).first().props().tags.length).toBe(1);
  });
});
