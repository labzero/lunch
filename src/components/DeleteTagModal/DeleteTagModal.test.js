/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import DeleteTagModal from '../DeleteTagModal';
import { Modal } from 'react-bootstrap';
import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { shallow } from 'enzyme';

describe('DeleteTagModal', () => {
  let props;

  beforeEach(() => {
    props = {
      tagName: 'gross',
      shown: true,
      hideModal: sinon.mock(),
      deleteTag: sinon.mock()
    };
  });

  it('renders confirmation text', () => {
    const wrapper = shallow(
      <DeleteTagModal {...props} />
    );
    expect(wrapper.find(Modal.Body).render().text())
      .to.contain('Are you sure you want to delete the "gross" tag?');
  });
});
