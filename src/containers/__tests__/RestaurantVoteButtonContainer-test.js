jest.unmock('../RestaurantVoteButtonContainer');
jest.unmock('react-redux');
jest.unmock('redux');
jest.unmock('normalizr');

import RestaurantVoteButtonContainer from '../RestaurantVoteButtonContainer';
import { removeVote, addVote } from '../../actions/restaurants';
import RestaurantVoteButton from '../../components/RestaurantVoteButton';
import React from 'react';
import { shallow } from 'enzyme';
import { createStore } from 'redux';
import action from '../../../test/helpers/action';
import { makeGetRestaurantVotesForUser } from '../../selectors';

describe('RestaurantVoteButtonContainer', () => {
  const state = {
    user: {
      id: 1
    }
  };
  let store;
  let props;

  beforeEach(() => {
    store = createStore(() => state, state);
    removeVote.mockImplementation(action);
    addVote.mockImplementation(action);
  });

  it('adds a vote when votes are empty', () => {
    makeGetRestaurantVotesForUser.mockImplementation(() => () => ([]));

    const wrapper = shallow(<RestaurantVoteButtonContainer {...props} />, { context: { store } });
    wrapper.find(RestaurantVoteButton).first().props().handleClick();
    expect(addVote.mock.calls.length).toBe(1);
  });

  it('removes a vote when user has voted', () => {
    makeGetRestaurantVotesForUser.mockImplementation(() => () => ([{
      restaurant_id: 1,
      user_id: 1
    }]));

    const wrapper = shallow(<RestaurantVoteButtonContainer {...props} />, { context: { store } });
    wrapper.find(RestaurantVoteButton).first().props().handleClick();
    expect(removeVote.mock.calls.length).toBe(1);
  });
});
