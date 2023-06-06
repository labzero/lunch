/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from "react";
import PropTypes from "prop-types";
import { expect } from "chai";
import { render, screen } from "../../../test/test-utils";
import {
  _RestaurantVoteCount as RestaurantVoteCount,
  RestaurantVoteCountProps,
} from "./RestaurantVoteCount";

describe("RestaurantAddTagForm", () => {
  let props: RestaurantVoteCountProps;

  beforeEach(() => {
    props = {
      id: 1,
      votes: [1],
      user: { id: 1 },
    };
  });

  const renderComponent = () => {
    class RestaurantVoteCountWithContext extends React.Component<RestaurantVoteCountProps> {
      static childContextTypes = {
        store: PropTypes.shape({}).isRequired,
      };

      getChildContext() {
        return { store: {} };
      }

      render() {
        return <RestaurantVoteCount {...this.props} />;
      }
    }

    return render(<RestaurantVoteCountWithContext {...props} />);
  };

  it("counts votes when a vote is added", async () => {
    renderComponent();
    expect(await screen.findByText("1")).to.be.in.document;
  });
});
