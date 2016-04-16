/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import { _RestaurantVoteButton as RestaurantVoteButton } from './RestaurantVoteButton';
import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';

describe('RestaurantVoteButton', () => {
  let props;

  beforeEach(() => {
    props = {
      handleClick: sinon.mock(),
      userVotes: []
    };
  });

  it('renders -1 when user has already voted', () => {
    props.userVotes.push({ id: 1 });

    const wrapper = shallow(<RestaurantVoteButton {...props} />);
    expect(wrapper.text()).to.eq('-1');
  });
});
