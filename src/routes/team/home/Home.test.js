/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from 'react';
import { spy, useFakeTimers } from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { _Home as Home } from './Home';
import RestaurantAddFormContainer from '../../../components/RestaurantAddForm/RestaurantAddFormContainer';

describe('Home', () => {
  let props;
  let fetchDecision;
  let fetchRestaurants;
  let fetchTags;
  let fetchUsers;
  let invalidateDecision;
  let invalidateRestaurants;
  let invalidateTags;
  let invalidateUsers;

  beforeEach(() => {
    fetchDecision = spy();
    fetchRestaurants = spy();
    fetchTags = spy();
    fetchUsers = spy();
    invalidateDecision = spy();
    invalidateRestaurants = spy();
    invalidateTags = spy();
    invalidateUsers = spy();
    props = {
      fetchDecision,
      fetchRestaurants,
      fetchTags,
      fetchUsers,
      invalidateDecision,
      invalidateRestaurants,
      invalidateTags,
      invalidateUsers,
      messageReceived: () => {},
      user: {},
      wsPort: 3000
    };
  });

  it('renders form if user is logged in', () => {
    props.user.id = 1;

    const wrapper = shallow(<Home {...props} />);

    expect(wrapper.find(RestaurantAddFormContainer).length).to.eq(1);
  });

  it('invalidates and fetches all data upon mount', () => {
    shallow(<Home {...props} />);

    expect(invalidateDecision.callCount).to.eq(1);
    expect(invalidateRestaurants.callCount).to.eq(1);
    expect(invalidateTags.callCount).to.eq(1);
    expect(invalidateUsers.callCount).to.eq(1);

    expect(fetchDecision.callCount).to.eq(1);
    expect(fetchRestaurants.callCount).to.eq(1);
    expect(fetchTags.callCount).to.eq(1);
    expect(fetchUsers.callCount).to.eq(1);
  });

  it('fetches all data after an hour', () => {
    const clock = useFakeTimers();

    shallow(<Home {...props} />);

    clock.tick(1000 * 60 * 60);

    expect(fetchDecision.callCount).to.eq(2);
    expect(fetchRestaurants.callCount).to.eq(2);
    expect(fetchTags.callCount).to.eq(2);
    expect(fetchUsers.callCount).to.eq(2);

    clock.restore();
  });
});
