jest.unmock('../../../core/ContextHolder');
jest.unmock('../App');

import ContextHolder from '../../../core/ContextHolder';
import App from '../App';
import React from 'react';
import { shallow } from 'enzyme';

describe('App', () => {
  it('renders children correctly', () => {
    const messageReceived = jest.fn();
    const modals = {};

    const wrapper = shallow(
      <ContextHolder context={{ insertCss: () => {} }}>
        <App messageReceived={messageReceived} modals={modals}>
          <div className="child" />
        </App>
      </ContextHolder>
    );
    expect(wrapper.contains(<div className="child" />)).toBe(true);
  });
});
