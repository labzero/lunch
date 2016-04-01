jest.unmock('../RestaurantVoteButton');

import { _RestaurantVoteButton as RestaurantVoteButton } from '../RestaurantVoteButton';
import React from 'react';
import { shallow } from 'enzyme';

describe('RestaurantVoteButton', () => {
  let props;

  beforeEach(() => {
    props = {
      handleClick: jest.fn(),
      user: { id: 1 },
      votes: []
    };
  });

  it('renders -1 when user has already voted', () => {
    props.votes.push({ user_id: 1 });

    const wrapper = shallow(<RestaurantVoteButton {...props} />);
    expect(wrapper.text()).toEqual('-1');
  });
});
