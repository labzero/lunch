/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import { expect } from "chai";
import React from "react";
import sinon from "sinon";
import { render, screen } from "../../../test/test-utils";
import ConfirmModal from "./ConfirmModal";

describe("ConfirmModal", () => {
  let props;

  beforeEach(() => {
    props = {
      actionLabel: "Delete",
      body: "Are you sure?",
      shown: true,
      hideModal: sinon.mock(),
      handleSubmit: sinon.mock(),
    };
  });

  it("renders confirmation text", async () => {
    render(<ConfirmModal {...props} />);

    expect(await screen.findByText("Are you sure?")).to.be.in.document;
  });
});
