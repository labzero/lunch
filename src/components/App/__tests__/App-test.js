jest.unmock('../App');

import App from '../App';
import React from 'react';
import { shallow } from 'enzyme';

const context = { insertCss: () => {} };

describe('App', () => {
  let props;

  beforeEach(() => {
    props = {
      wsPort: 3000,
      messageReceived: jest.fn(),
      shouldScrollToTop: false,
      scrolledToTop: jest.fn()
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
});
