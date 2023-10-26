/* eslint-env mocha */
/* eslint-disable padded-blocks, no-unused-expressions */

import React from "react";
import { SinonSpy, spy, useFakeTimers } from "sinon";
import { expect } from "chai";
import proxyquire from "proxyquire";
import { render, screen } from "../../../../test/test-utils";
import { HomeProps } from "./Home";
import { User } from "../../../interfaces";
import mockEsmodule from "test/mockEsmodule";

const proxy = proxyquire.noCallThru();

const FooterContainer = () => <div>Stubbed footercontainer.</div>;
const NameFilterFormContainer = () => (
  <div>Stubbed name filter form container.</div>
);
const PastDecisionsModalContainer = () => (
  <div>Stubbed past decisions modal container.</div>
);
const RestaurantMapContainer = () => (
  <div>Stubbed restaurant map container.</div>
);
const RestaurantListContainer = () => (
  <div>Stubbed restaurant list container.</div>
);
const RestaurantAddFormContainer = () => (
  <div>Stubbed restaurant add form container.</div>
);
const TagFilterFormContainer = () => (
  <div>Stubbed tag filter form container.</div>
);

// eslint-disable-next-line no-underscore-dangle
const Home = proxy("./Home", {
  "../../../helpers/canUseDOM": mockEsmodule({
    default: false,
  }),
  "../../../components/RestaurantAddForm/RestaurantAddFormContainer":
    RestaurantAddFormContainer,
  "../../../components/Footer/FooterContainer": FooterContainer,
  "../../../components/NameFilterForm/NameFilterFormContainer":
    NameFilterFormContainer,
  "../../../components/PastDecisionsModal/PastDecisionsModalContainer":
    PastDecisionsModalContainer,
  "../../../components/RestaurantMap/RestaurantMapContainer":
    RestaurantMapContainer,
  "../../../components/RestaurantList/RestaurantListContainer":
    RestaurantListContainer,
  "../../../components/TagFilterForm/TagFilterFormContainer":
    TagFilterFormContainer,
})._Home;

describe("Home", () => {
  let props: HomeProps;
  let fetchDecisions: SinonSpy;
  let fetchRestaurants: SinonSpy;
  let fetchTags: SinonSpy;
  let fetchUsers: SinonSpy;
  let invalidateDecisions: SinonSpy;
  let invalidateRestaurants: SinonSpy;
  let invalidateTags: SinonSpy;
  let invalidateUsers: SinonSpy;

  beforeEach(() => {
    fetchDecisions = spy();
    fetchRestaurants = spy();
    fetchTags = spy();
    fetchUsers = spy();
    invalidateDecisions = spy();
    invalidateRestaurants = spy();
    invalidateTags = spy();
    invalidateUsers = spy();
    props = {
      fetchDecisions,
      fetchRestaurants,
      fetchTags,
      fetchUsers,
      invalidateDecisions,
      invalidateRestaurants,
      invalidateTags,
      invalidateUsers,
      messageReceived: () => undefined,
      pastDecisionsShown: false,
      port: 3000,
      user: null,
    };
  });

  const renderComponent = async () => {
    render(<Home {...props} />);

    expect(await screen.findByText("Stubbed restaurant map container.")).to.be
      .in.document;
  };

  it("renders form if user is logged in", async () => {
    props.user = { id: 1 } as User;

    await renderComponent();

    expect(await screen.findByText("Stubbed restaurant add form container.")).to
      .be.in.document;
  });

  it("invalidates and fetches all data upon mount", async () => {
    await renderComponent();

    expect(invalidateDecisions.callCount).to.eq(1);
    expect(invalidateRestaurants.callCount).to.eq(1);
    expect(invalidateTags.callCount).to.eq(1);
    expect(invalidateUsers.callCount).to.eq(1);

    expect(fetchDecisions.callCount).to.eq(1);
    expect(fetchRestaurants.callCount).to.eq(1);
    expect(fetchTags.callCount).to.eq(1);
    expect(fetchUsers.callCount).to.eq(1);
  });

  it("fetches all data after an hour", async () => {
    const clock = useFakeTimers({ shouldAdvanceTime: true });

    await renderComponent();

    clock.tick(1000 * 60 * 60);

    expect(fetchDecisions.callCount).to.eq(2);
    expect(fetchRestaurants.callCount).to.eq(2);
    expect(fetchTags.callCount).to.eq(2);
    expect(fetchUsers.callCount).to.eq(2);

    clock.restore();
  });
});
