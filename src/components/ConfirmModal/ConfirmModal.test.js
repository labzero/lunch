/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import Modal from 'react-bootstrap/Modal';
import { expect } from 'chai';
import React from 'react';
import sinon from 'sinon';
import { shallow } from 'enzyme';
import ConfirmModal from './ConfirmModal';

describe('ConfirmModal', () => {
  let props;

  beforeEach(() => {
    props = {
      actionLabel: 'Delete',
      body: 'Are you sure?',
      shown: true,
      hideModal: sinon.mock(),
      handleSubmit: sinon.mock()
    };
  });

  it('renders confirmation text', () => {
    const wrapper = shallow(
      <ConfirmModal {...props} />
    );
    expect(wrapper.find(Modal.Body).render().text())
      .to.eq('Are you sure?');
  });
});
