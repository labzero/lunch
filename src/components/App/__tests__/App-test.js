jest.unmock('../App');

import App from '../App';
import DeleteRestaurantModalContainer from '../../../containers/DeleteRestaurantModalContainer';
import React from 'react';
import { shallow } from 'enzyme';

const context = { insertCss: () => {} };

describe('App', () => {
  let messageReceived;
  let modals;

  beforeEach(() => {
    messageReceived = jest.fn();
    modals = {};
    window.WebSocket = jest.fn();
  });

  it('renders children correctly', () => {
    const wrapper = shallow(
      <App messageReceived={messageReceived} modals={modals}>
        <div className="child" />
      </App>,
    { context });
    expect(wrapper.contains(<div className="child" />)).toBe(true);
  });

  it('adds a modal if there is data', () => {
    modals.deleteRestaurant = { name: 'Food Barn' };
    const wrapper = shallow(
      <App messageReceived={messageReceived} modals={modals}><div /></App>,
    { context });
    expect(wrapper.find(DeleteRestaurantModalContainer).length).toBe(1);
  });
});
