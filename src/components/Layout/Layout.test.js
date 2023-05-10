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
import PropTypes from 'prop-types';
import { expect } from 'chai';
import proxyquire from 'proxyquire';
import { render, screen } from '../../../test/test-utils';

const proxy = proxyquire.noCallThru();

const HeaderContainer = () => <div>Stubbed header container.</div>;
const FooterContainer = () => <div>Stubbed footer container.</div>;
const ConfirmModalContainer = () => <div>Stubbed confirm modal container.</div>;
const NotificationListContainer = () => <div>Stubbed notification list container.</div>;

const Layout = proxy('./Layout', {
  '../Header/HeaderContainer': HeaderContainer,
  '../Footer/FooterContainer': FooterContainer,
  '../ConfirmModal/ConfirmModalContainer': ConfirmModalContainer,
  '../NotificationList/NotificationListContainer': NotificationListContainer,
}).default;

describe('Layout', () => {
  let props;

  beforeEach(() => {
    props = {
      children: <div>Child</div>,
      confirmShown: false,
      shouldScrollToTop: false,
      scrolledToTop: () => undefined
    };
  });

  const renderComponent = () => {
    class LayoutWithContext extends React.Component {
      static childContextTypes = {
        insertCss: PropTypes.func.isRequired
      };

      getChildContext() {
        return { insertCss: () => undefined };
      }

      render() {
        return <Layout {...this.props} />;
      }
    }

    return render(<LayoutWithContext {...props} />);
  };

  it('renders children correctly', async () => {
    renderComponent();

    expect(await screen.findByText('Child')).to.be.in.document;
  });

  it('does not render the FooterContainer component if the isHome prop is true', async () => {
    props.isHome = true;

    renderComponent();

    expect(await screen.queryByText('Stubbed footer container.')).not.to.be.in.document;
  });

  it('renders the FooterContainer component if the isHome prop is false', async () => {
    props.isHome = false;

    renderComponent();

    expect(await screen.findByText('Stubbed footer container.')).to.be.in.document;
  });

  it('renders the FooterContainer component if the isHome prop is left undefined', async () => {
    renderComponent();

    expect(await screen.findByText('Stubbed footer container.')).to.be.in.document;
  });

  it('renders the ConfirmModalContainer component if the confirmShown prop is set to true', async () => {
    props.confirmShown = true;

    renderComponent();

    expect(await screen.findByText('Stubbed confirm modal container.')).to.be.in.document;
  });

  it('does not render the ConfirmModalContainer component if the confirmShown prop is set to false', async () => {
    props.confirmShown = false;

    renderComponent();

    expect(await screen.queryByText('Stubbed confirm modal container.')).not.to.be.in.document;
  });
});
