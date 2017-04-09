/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import ModalSection from './ModalSection';
import ConfirmModalContainer from '../ConfirmModal/ConfirmModalContainer';

const context = { insertCss: () => {} };

describe('ModalSection', () => {
  let props;

  beforeEach(() => {
    props = {
      modals: {}
    };
  });

  it('adds a modal if there is data', () => {
    props.modals.confirm = { body: 'Are you sure?' };
    const wrapper = shallow(
      <ModalSection {...props}><div /></ModalSection>,
    { context });
    expect(wrapper.find(ConfirmModalContainer).length).to.eq(1);
  });
});
