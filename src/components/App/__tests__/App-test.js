jest.unmock('../App');

import App from '../App';
import DeleteRestaurantModalContainer from '../../../containers/DeleteRestaurantModalContainer';
import React from 'react';
import { shallow } from 'enzyme';

const context = { insertCss: () => {} };

describe('App', () => {
  let props;

  beforeEach(() => {
    props = {
      modals: {},
      wsPort: 3000,
      messageReceived: jest.fn(),
      shouldScrollToTop: false,
      scrolledToTop: jest.fn(),
      notifications: []
    };
    window.ReconnectingWebSocket = jest.fn();
  });

  it('renders children correctly', () => {
    const wrapper = shallow(
      <App {...props}>
        <div className="child" />
      </App>,
    { context });
    expect(wrapper.contains(<div className="child" />)).toBe(true);
  });

  it('adds a modal if there is data', () => {
    props.modals.deleteRestaurant = { name: 'Food Barn' };
    const wrapper = shallow(
      <App {...props}><div /></App>,
    { context });
    expect(wrapper.find(DeleteRestaurantModalContainer).length).toBe(1);
  });
});
