/* eslint-env mocha */
import { expect } from "chai";
import proxyquire from "proxyquire";
import { Restaurant } from "../../interfaces";

describe("selectors/index", () => {
  describe("getFilteredRestaurants", () => {
    let restaurantIds: number[];
    let nameFilter: string;
    let tagFilters: number[];
    let tagExclusions: number[];
    let restaurantEntities: { [index: number]: Restaurant };
    const proxyIndex = proxyquire("../index", {
      "./restaurants": {
        getRestaurantIds: () => restaurantIds,
        getNameFilter: () => nameFilter,
        getRestaurantEntities: () => restaurantEntities,
      },
      "./tagFilters": {
        getTagFilters: () => tagFilters,
      },
      "./tagExclusions": {
        getTagExclusions: () => tagExclusions,
      },
    });

    beforeEach(() => {
      restaurantIds = [1, 2];
      nameFilter = "";
      tagFilters = [];
      tagExclusions = [];
      restaurantEntities = {
        1: {
          id: 1,
          name: "foo",
          tags: [1],
        } as Restaurant,
        2: {
          id: 1,
          name: "bar",
          tags: [] as number[],
        } as Restaurant,
      };
    });

    it("returns restaurantIds when no filters are applied", () => {
      expect(proxyIndex.getFilteredRestaurants()).to.eql(restaurantIds);
    });

    it("returns matching restaurants when filtered by name", () => {
      nameFilter = "foo";
      expect(proxyIndex.getFilteredRestaurants()).to.eql([1]);
    });

    it("returns matching restaurants when filtered by tag", () => {
      tagFilters = [1];
      expect(proxyIndex.getFilteredRestaurants()).to.eql([1]);
    });

    it("returns restaurants without tag when filtered by tag exclusion", () => {
      tagExclusions = [1];
      expect(proxyIndex.getFilteredRestaurants()).to.eql([2]);
    });

    it("returns empty array when no restaurants meet search criteria", () => {
      tagFilters = [2];
      expect(proxyIndex.getFilteredRestaurants()).to.eql([]);
    });
  });
});
