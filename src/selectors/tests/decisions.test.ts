/* eslint-env mocha */
import dayjs from "dayjs";
import { expect } from "chai";
import { getDecisionsByDay } from "../decisions";
import { Decision, State } from "../../interfaces";

describe("selectors/decisions", () => {
  describe("getDecisionsByDay", () => {
    let state: Pick<State, "decisions">;
    beforeEach(() => {
      const now = dayjs();

      state = {
        decisions: {
          didInvalidate: false,
          isFetching: false,
          items: {
            result: [1, 2, 3, 4],
            entities: {
              decisions: {
                1: {
                  createdAt: dayjs(now).toDate(),
                } as Decision,
                2: {
                  createdAt: dayjs(now).subtract(23, "hours").toDate(),
                } as Decision,
                3: {
                  createdAt: dayjs(now).subtract(25, "hours").toDate(),
                } as Decision,
                4: {
                  createdAt: dayjs(now).subtract(48, "hours").toDate(),
                } as Decision,
              },
            },
          },
        },
      };
    });

    it("groups decisions into per-day arrays", () => {
      const decisions = state.decisions.items.entities.decisions;
      expect(getDecisionsByDay(state as State)).to.eql({
        0: [decisions[1]],
        1: [decisions[2], decisions[3]],
        2: [decisions[4]],
        3: [],
        4: [],
      });
    });
  });
});
