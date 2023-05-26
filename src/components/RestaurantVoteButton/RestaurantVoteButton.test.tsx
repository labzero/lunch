/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from "react";
import sinon from "sinon";
import { expect } from "chai";
import { render, screen } from "../../../test/test-utils";
import {
  _RestaurantVoteButton as RestaurantVoteButton,
  RestaurantVoteButtonProps,
} from "./RestaurantVoteButton";

describe("RestaurantVoteButton", () => {
  let props: RestaurantVoteButtonProps;

  beforeEach(() => {
    props = {
      handleClick: sinon.mock(),
      userVotes: [],
    };
  });

  it("renders -1 when user has already voted", async () => {
    props.userVotes.push({ id: 1 });

    render(<RestaurantVoteButton {...props} />);
    expect(await screen.findByText("-1")).to.be.in.document;
  });
});
