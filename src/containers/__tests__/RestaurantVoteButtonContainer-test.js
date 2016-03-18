jest.unmock('../RestaurantVoteButtonContainer');
jest.unmock('react-redux');

import RestaurantVoteButtonContainer from '../RestaurantVoteButtonContainer';
import { removeVote, addVote } from '../../actions/restaurants';
import RestaurantVoteButton from '../../components/RestaurantVoteButton';
import React from 'react';

// import { Provider } from 'react-redux';
import { shallow } from 'enzyme';

describe('RestaurantAddTagForm', () => {
  let store;
  let props;

  beforeEach(() => {
    store = {
      getState: () => ({
        user: {
          id: 1
        }
      }),
      subscribe: jest.fn(),
      dispatch: jest.fn()
    };
  });

  it('adds a vote when votes are empty', () => {
    props = {
      votes: []
    };

    const wrapper = shallow(<RestaurantVoteButtonContainer {...props} />, { context: { store } });
    wrapper.find(RestaurantVoteButton).first().props().handleClick();
    expect(addVote.mock.calls.length).toBe(1);
  });

  it('removes a vote when user has voted', () => {
    props = {
      votes: [{
        restaurant_id: 1,
        user_id: 1
      }]
    };

    const wrapper = shallow(<RestaurantVoteButtonContainer {...props} />, { context: { store } });
    wrapper.find(RestaurantVoteButton).first().props().handleClick();
    expect(removeVote.mock.calls.length).toBe(1);
  });
});
