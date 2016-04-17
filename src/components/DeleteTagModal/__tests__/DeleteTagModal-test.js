jest.unmock('../DeleteTagModal');

import DeleteTagModal from '../DeleteTagModal';
import { Modal } from 'react-bootstrap';
import React from 'react';
import { shallow } from 'enzyme';

describe('DeleteTagModal', () => {
  let props;

  beforeEach(() => {
    props = {
      tagName: 'gross',
      shown: true,
      hideModal: jest.fn(),
      deleteTag: jest.fn()
    };
  });

  it('renders confirmation text', () => {
    const wrapper = shallow(
      <DeleteTagModal {...props} />
    );
    expect(wrapper.find(Modal.Body).render().text()).toContain('Are you sure you want to delete the "gross" tag?');
  });
});
