/* eslint-env mocha */
/* eslint-disable no-unused-expressions */
import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import proxyquire from 'proxyquire';
import PropTypes from 'prop-types';

const proxyquireStrict = proxyquire.noCallThru();

const AddUserForm = proxyquireStrict('./AddUserForm', {
  'react-intl': {
    intlShape: {
      isRequired: PropTypes.shape().isRequired,
    },
  }
}).default;

describe('AddUserForm', () => {
  let props;

  beforeEach(() => {
    props = {
      addUserToTeam: () => {},
      hasGuestRole: false,
      hasMemberRole: false,
      hasOwnerRole: false,
      intl: {
        formatMessage: () => {},
      },
    };
  });

  describe('the options for the User Type form', () => {
    it('includes an option for guest if the hasGuestRole prop is true', () => {
      props.hasGuestRole = true;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(<option value="guest" />)).to.be.true;
    });

    it('does not include an option for guest if the hasGuestRole prop is false', () => {
      props.hasGuestRole = false;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(<option value="guest" />)).to.be.false;
    });

    it('includes an option for member if the hasMemberRole prop is true', () => {
      props.hasMemberRole = true;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(<option value="member" />)).to.be.true;
    });

    it('does not include an option for member if the hasMemberRole prop is false', () => {
      props.hasMemberRole = false;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(<option value="member" />)).to.be.false;
    });

    it('includes an option for owner if the hasOwnerRole prop is true', () => {
      props.hasOwnerRole = true;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(<option value="owner" />)).to.be.true;
    });

    it('does not include an option for owner if the hasOwnerRole prop is false', () => {
      props.hasOwnerRole = false;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(<option value="owner" />)).to.be.false;
    });
  });

  describe('the HelpBlock for the AddUserForm', () => {
    const ownerHelpString = ' Owners can manage all user roles and manage overall team information.';
    it('contains additional guidance for owners if the hasOwnerRole is true', () => {
      props.hasOwnerRole = true;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(ownerHelpString)).to.be.true;
    });

    it('does not contain additional guidance for owners if the hasOwnerRole is false', () => {
      props.hasOwnerRole = false;

      const wrapper = shallow(<AddUserForm {...props} />);

      expect(wrapper.contains(ownerHelpString)).to.be.false;
    });
  });
});
