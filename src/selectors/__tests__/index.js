jest.unmock('..');
jest.unmock('../helpers');
jest.unmock('reselect');

import { getTags } from '../tags';
import { makeGetTagList } from '..';

describe('selectors', () => {
  describe('makeGetTagList', () => {
    let getTagList;
    let state;

    beforeEach(() => {
      state = {};
      getTags.mockImplementation(() => [{
        id: 1,
        name: 'take out'
      }, {
        id: 2,
        name: 'friday'
      }, {
        id: 3,
        name: 'gross'
      }, {
        id: 4,
        name: 'mexican'
      }, {
        id: 5,
        name: 'italian'
      }, {
        id: 6,
        name: 'sandwiches'
      }, {
        id: 7,
        name: 'ramen'
      }, {
        id: 8,
        name: 'truck'
      }, {
        id: 9,
        name: 'expensive'
      }, {
        id: 10,
        name: 'touristy'
      }, {
        id: 11,
        name: 'chain'
      }]);

      getTagList = makeGetTagList();
    });

    it('returns up to 10 tags', () => {
      expect(getTagList(state, { addedTags: [], autosuggestValue: '' }).length).toBe(10);
    });

    it('omits added tags', () => {
      expect(getTagList(state, { addedTags: [1, 2, 3, 4, 5], autosuggestValue: '' }).length).toBe(6);
    });

    it('filters by query and added tags', () => {
      expect(getTagList(state, { addedTags: [4], autosuggestValue: 'x' }).length).toBe(1);
    });
  });
});
