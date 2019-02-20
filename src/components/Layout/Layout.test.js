/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import proxyquire from 'proxyquire';

const context = { insertCss: () => {} };

const proxy = proxyquire.noCallThru();

const FooterContainer = () => <div>Stubbed footer container.</div>;
const ConfirmModalContainer = () => <div>Stubbed confirm modal container.</div>;

const Layout = proxy('./Layout', {
  '../Footer/FooterContainer': FooterContainer,
  '../ConfirmModal/ConfirmModalContainer': ConfirmModalContainer
}).default;

describe('Layout', () => {
  let props;

  beforeEach(() => {
    props = {
      shouldScrollToTop: false,
      scrolledToTop: () => {}
    };
  });

  it('renders children correctly', () => {
    const wrapper = shallow(
      <Layout {...props}>
        <div className="child" />
      </Layout>,
      { context }
    );

    expect(wrapper.contains(<div className="child" />)).to.be.true;
  });

  it('does not render the FooterContainer component if the isHome prop is true', () => {
    props.isHome = true;
    const wrapper = shallow(
      <Layout {...props} />,
      { context }
    );

    expect(wrapper.find('FooterContainer')).to.have.length(0);
  });

  it('renders the FooterContainer component if the isHome prop is false', () => {
    props.isHome = false;

    const wrapper = shallow(
      <Layout {...props} />,
      { context }
    );

    expect(wrapper.find('FooterContainer')).to.have.length(1);
  });

  it('renders the FooterContainer component if the isHome prop is left undefined', () => {
    const wrapper = shallow(
      <Layout {...props} />,
      { context }
    );

    expect(wrapper.find('FooterContainer')).to.have.length(1);
  });

  it('renders the ConfirmModalContainer component if the confirmShown prop is set to true', () => {
    props.confirmShown = true;
    const wrapper = shallow(
      <Layout {...props} />,
      { context }
    );

    expect(wrapper.find('ConfirmModalContainer')).to.have.length(1);
  });

  it('does not render the ConfirmModalContainer component if the confirmShown prop is set to false', () => {
    props.confirmShown = false;
    const wrapper = shallow(
      <Layout {...props} />,
      { context }
    );

    expect(wrapper.find('ConfirmModalContainer')).to.have.length(0);
  });
});
