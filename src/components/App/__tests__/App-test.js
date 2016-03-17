jest.unmock('../App');

import App from '../App';
import React from 'react';
import { shallow } from 'enzyme';

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
    { context: { insertCss: () => {} } });
    expect(wrapper.contains(<div className="child" />)).toBe(true);
  });
});
