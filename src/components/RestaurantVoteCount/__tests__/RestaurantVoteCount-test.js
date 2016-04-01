jest.unmock('../RestaurantVoteCount');

import { _RestaurantVoteCount as RestaurantVoteCount } from '../RestaurantVoteCount';
import React from 'react';
import { shallow } from 'enzyme';

describe('RestaurantAddTagForm', () => {
  let props;

  beforeEach(() => {
    props = {
      votes: [],
      user: {},
      users: []
    };
  });

  it('counts votes when a vote is added', () => {
    const wrapper = shallow(<RestaurantVoteCount {...props} />);
    wrapper.setProps({ votes: [{ restaurant_id: 1 }] });
    expect(wrapper.render().text()).toBe('1 vote');
  });
});
