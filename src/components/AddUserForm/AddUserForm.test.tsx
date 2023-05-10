/* eslint-env mocha */
/* eslint-disable no-unused-expressions */
import React from 'react';
import { expect } from 'chai';
import proxyquire from 'proxyquire';
import PropTypes from 'prop-types';
import { render, screen, within } from '../../../test/test-utils';
import { AddUserFormProps } from './AddUserForm';

const proxyquireStrict = proxyquire.noCallThru();

const AddUserForm = proxyquireStrict('./AddUserForm', {
  'react-intl': {
    intlShape: {
      isRequired: PropTypes.shape({}).isRequired,
    },
  }
}).default;

interface MockAddUserFormProps extends Omit<AddUserFormProps, 'intl'> {
  intl: unknown
}

describe('AddUserForm', () => {
  let props: MockAddUserFormProps;

  beforeEach(() => {
    props = {
      addUserToTeam: () => undefined,
      hasGuestRole: false,
      hasMemberRole: false,
      hasOwnerRole: false,
      intl: {
        formatMessage: () => '',
      },
    };
  });

  const renderComponent = () => render(<AddUserForm {...props} />);

  describe('the options for the User Type form', () => {
    const getTypeSelectOptions = async () => {
      renderComponent();

      const select = await screen.findByLabelText('Type');

      const options = within(select).queryAllByRole('option').map((el => (el as HTMLOptionElement).value));

      return options;
    };

    it('includes an option for guest if the hasGuestRole prop is true', async () => {
      props.hasGuestRole = true;

      expect(await getTypeSelectOptions()).to.contain('guest');
    });

    it('does not include an option for guest if the hasGuestRole prop is false', async () => {
      props.hasGuestRole = false;

      expect(await getTypeSelectOptions()).not.to.contain('guest');
    });

    it('includes an option for member if the hasMemberRole prop is true', async () => {
      props.hasMemberRole = true;

      expect(await getTypeSelectOptions()).to.contain('member');
    });

    it('does not include an option for member if the hasMemberRole prop is false', async () => {
      props.hasMemberRole = false;

      expect(await getTypeSelectOptions()).not.to.contain('member');
    });

    it('includes an option for owner if the hasOwnerRole prop is true', async () => {
      props.hasOwnerRole = true;

      expect(await getTypeSelectOptions()).to.contain('owner');
    });

    it('does not include an option for owner if the hasOwnerRole prop is false', async () => {
      props.hasOwnerRole = false;

      expect(await getTypeSelectOptions()).not.to.contain('owner');
    });
  });

  describe('the HelpBlock for the AddUserForm', () => {
    const ownerHelpString = 'Members can add new users and remove guests. Owners can manage all user roles and manage overall team information.';
    it('contains additional guidance for owners if the hasOwnerRole is true', async () => {
      props.hasOwnerRole = true;

      renderComponent();

      expect(await screen.findByText(ownerHelpString)).to.be.in.document;
    });

    it('does not contain additional guidance for owners if the hasOwnerRole is false', async () => {
      props.hasOwnerRole = false;

      renderComponent();

      expect(await screen.queryByText(ownerHelpString)).not.to.be.in.document;
    });
  });
});
