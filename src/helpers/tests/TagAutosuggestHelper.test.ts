/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import { expect } from "chai";
import { generateTagList } from "../TagAutosuggestHelper";
import { Tag } from "../../interfaces";

describe("TagAutosuggestHelper", () => {
  describe("generateTagList", () => {
    let tags: Tag[];

    beforeEach(() => {
      tags = [
        {
          id: 1,
          name: "take out",
        },
        {
          id: 2,
          name: "friday",
        },
        {
          id: 3,
          name: "gross",
        },
        {
          id: 4,
          name: "mexican",
        },
        {
          id: 5,
          name: "italian",
        },
        {
          id: 6,
          name: "sandwiches",
        },
        {
          id: 7,
          name: "ramen",
        },
        {
          id: 8,
          name: "truck",
        },
        {
          id: 9,
          name: "expensive",
        },
        {
          id: 10,
          name: "touristy",
        },
        {
          id: 11,
          name: "chain",
        },
      ] as Tag[];
    });

    it("returns up to 10 tags", () => {
      expect(generateTagList(tags, [], "").length).to.eq(10);
    });

    it("omits added tags", () => {
      expect(generateTagList(tags, [1, 2, 3, 4, 5], "").length).to.eq(6);
    });

    it("filters by query and added tags", () => {
      expect(generateTagList(tags, [4], "x").length).to.eq(1);
    });
  });
});
