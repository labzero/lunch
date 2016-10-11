/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { _RestaurantVoteCount as RestaurantVoteCount } from './RestaurantVoteCount';

describe('RestaurantAddTagForm', () => {
  let props;

  beforeEach(() => {
    props = {
      id: 1,
      votes: [],
      user: {},
      users: []
    };
  });

  it('counts votes when a vote is added', () => {
    const wrapper = shallow(<RestaurantVoteCount {...props} />);
    wrapper.setProps({ votes: [{ restaurant_id: 1 }] });
    expect(wrapper.render().text()).to.eq('1 vote');
  });
});
