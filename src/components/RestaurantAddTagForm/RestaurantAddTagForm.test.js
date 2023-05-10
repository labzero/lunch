/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from 'react';
import sinon from 'sinon';
import { expect } from 'chai';
import { render, screen } from '../../../test/test-utils';
import { _RestaurantAddTagForm as RestaurantAddTagForm } from './RestaurantAddTagForm';

describe('RestaurantAddTagForm', () => {
  let props;

  beforeEach(() => {
    props = {
      addedTags: [],
      addNewTagToRestaurant: sinon.mock(),
      addTagToRestaurant: () => undefined,
      hideAddTagForm: () => undefined,
      tags: []
    };
  });

  it('disables add button when autosuggest value is blank', async () => {
    render(<RestaurantAddTagForm {...props} />);
    expect((await screen.findAllByRole('button'))[0]).to.be.disabled;
  });
});
