jest.unmock('../DeleteTagModal');

import DeleteTagModal from '../DeleteTagModal';
import { Modal } from 'react-bootstrap';
import React from 'react';
import { shallow } from 'enzyme';

describe('DeleteTagModal', () => {
  let hideModal;
  let deleteTag;
  let tag;

  beforeEach(() => {
    hideModal = jest.fn();
    deleteTag = jest.fn();
  });

  it('renders confirmation text', () => {
    tag = {
      name: 'gross'
    };

    const wrapper = shallow(
      <DeleteTagModal tag={tag} shown hideModal={hideModal} deleteTag={deleteTag} />
    );
    expect(wrapper.find(Modal.Body).render().text()).toContain('Are you sure you want to delete the "gross" tag?');
  });

  it('keeps tag name upon tag deletion', () => {
    tag = {
      name: 'gross'
    };

    const wrapper = shallow(
      <DeleteTagModal tag={tag} shown hideModal={hideModal} deleteTag={deleteTag} />
    );
    wrapper.setProps({ tag: {} });
    expect(wrapper.find(Modal.Body).render().text()).toContain('Are you sure you want to delete the "gross" tag?');
  });
});
