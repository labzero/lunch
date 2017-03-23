/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as tags from '../tags';
import { __RewireAPI__ as tagsRewireAPI } from '../tags';
import actionCreatorStub from '../../../test/actionCreatorStub';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/tags', () => {
  let store;
  let teamSlug;
  let flashErrorStub;

  beforeEach(() => {
    store = mockStore({});
    teamSlug = 'labzero';
    flashErrorStub = actionCreatorStub();
    tagsRewireAPI.__Rewire__('flashError', flashErrorStub);
  });

  describe('fetchTags', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestTags', () => {
        const requestTagsStub = actionCreatorStub();
        tagsRewireAPI.__Rewire__('requestTags', requestTagsStub);

        store.dispatch(tags.fetchTags(teamSlug));

        expect(requestTagsStub.calledWith(teamSlug)).to.be.true;
      });

      it('fetches tags', () => {
        store.dispatch(tags.fetchTags(teamSlug));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/tags`);
      });
    });

    describe('success', () => {
      let receiveTagsStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
        receiveTagsStub = actionCreatorStub();
        tagsRewireAPI.__Rewire__('receiveTags', receiveTagsStub);
        return store.dispatch(tags.fetchTags(teamSlug));
      });

      it('dispatches receiveTags', () => {
        expect(receiveTagsStub.calledWith([{ foo: 'bar' }], teamSlug)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(tags.fetchTags(teamSlug));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('removeTag', () => {
    let id;
    beforeEach(() => {
      id = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteTag', () => {
        const deleteTagStub = actionCreatorStub();
        tagsRewireAPI.__Rewire__('deleteTag', deleteTagStub);

        store.dispatch(tags.removeTag(teamSlug, id));

        expect(deleteTagStub.calledWith(teamSlug, id)).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(tags.removeTag(teamSlug, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/tags/${id}`);
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(tags.removeTag(teamSlug, id));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });
});
