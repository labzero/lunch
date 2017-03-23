/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import configureStore from 'redux-mock-store';
import fetchMock from 'fetch-mock';
import thunk from 'redux-thunk';
import * as restaurants from '../restaurants';
import { __RewireAPI__ as restaurantsRewireAPI } from '../restaurants';
import actionCreatorStub from '../../../test/actionCreatorStub';

const middlewares = [thunk];
const mockStore = configureStore(middlewares);

describe('actions/restaurants', () => {
  let store;
  let teamSlug;
  let flashErrorStub;

  beforeEach(() => {
    store = mockStore({});
    teamSlug = 'labzero';
    flashErrorStub = actionCreatorStub();
    restaurantsRewireAPI.__Rewire__('flashError', flashErrorStub);
  });

  describe('fetchRestaurants', () => {
    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches requestRestaurants', () => {
        const requestRestaurantsStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('requestRestaurants', requestRestaurantsStub);

        store.dispatch(restaurants.fetchRestaurants(teamSlug));

        expect(requestRestaurantsStub.calledWith(teamSlug)).to.be.true;
      });

      it('fetches restaurants', () => {
        store.dispatch(restaurants.fetchRestaurants(teamSlug));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants`);
      });
    });

    describe('success', () => {
      let receiveRestaurantsStub;
      beforeEach(() => {
        fetchMock.mock('*', { data: [{ foo: 'bar' }] });
        receiveRestaurantsStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('receiveRestaurants', receiveRestaurantsStub);
        return store.dispatch(restaurants.fetchRestaurants(teamSlug));
      });

      it('dispatches receiveRestaurants', () => {
        expect(receiveRestaurantsStub.calledWith([{ foo: 'bar' }], teamSlug)).to.be.true;
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(restaurants.fetchRestaurants(teamSlug));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('addRestaurant', () => {
    let name;
    let placeId;
    let address;
    let lat;
    let lng;

    beforeEach(() => {
      name = 'Lab Zero';
      placeId = '12345';
      address = '123 Main';
      lat = 50;
      lng = 100;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postRestaurant', () => {
        const postRestaurantStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('postRestaurant', postRestaurantStub);

        store.dispatch(restaurants.addRestaurant(teamSlug, name, placeId, address, lat, lng));

        expect(postRestaurantStub.calledWith({
          name,
          place_id: placeId,
          address,
          lat,
          lng
        })).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(restaurants.addRestaurant(teamSlug, name, placeId, address, lat, lng));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({
          name,
          place_id: placeId,
          address,
          lat,
          lng
        }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.addRestaurant(teamSlug, name, placeId, address, lat, lng)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('removeRestaurant', () => {
    let id;
    beforeEach(() => {
      id = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteRestaurant', () => {
        const deleteRestaurantStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('deleteRestaurant', deleteRestaurantStub);

        store.dispatch(restaurants.removeRestaurant(teamSlug, id));

        expect(deleteRestaurantStub.calledWith(teamSlug, id)).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(restaurants.removeRestaurant(teamSlug, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${id}`);
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(restaurants.removeRestaurant(teamSlug));
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('changeRestaurantName', () => {
    let id;
    let name;

    beforeEach(() => {
      id = 1;
      name = 'Lab Zero';
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches renameRestaurant', () => {
        const renameRestaurantStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('renameRestaurant', renameRestaurantStub);

        store.dispatch(restaurants.changeRestaurantName(teamSlug, id, name));

        expect(renameRestaurantStub.calledWith(teamSlug, id, { name })).to.be.true;
      });

      it('fetches restaurant', () => {
        store.dispatch(restaurants.changeRestaurantName(teamSlug, id, name));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${id}`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ name }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.changeRestaurantName(teamSlug, id, name)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('addVote', () => {
    let id;
    beforeEach(() => {
      id = 1;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postVote', () => {
        const postVoteStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('postVote', postVoteStub);

        store.dispatch(restaurants.addVote(teamSlug, id));

        expect(postVoteStub.calledWith(teamSlug, id)).to.be.true;
      });

      it('fetches vote', () => {
        store.dispatch(restaurants.addVote(teamSlug, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${id}/votes`);
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.addVote(teamSlug, id)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('removeVote', () => {
    let restaurantId;
    let id;
    beforeEach(() => {
      restaurantId = 1;
      id = 2;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteVote', () => {
        const deleteVoteStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('deleteVote', deleteVoteStub);

        store.dispatch(restaurants.removeVote(teamSlug, restaurantId, id));

        expect(deleteVoteStub.calledWith(teamSlug, restaurantId, id)).to.be.true;
      });

      it('fetches vote', () => {
        store.dispatch(restaurants.removeVote(teamSlug, restaurantId, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${restaurantId}/votes/${id}`);
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.removeVote(teamSlug, restaurantId, id)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('addNewTagToRestaurant', () => {
    let id;
    let name;
    beforeEach(() => {
      id = 1;
      name = 'zap';
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postNewTagToRestaurant', () => {
        const postNewTagToRestaurantStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('postNewTagToRestaurant', postNewTagToRestaurantStub);

        store.dispatch(restaurants.addNewTagToRestaurant(teamSlug, id, name));

        expect(postNewTagToRestaurantStub.calledWith(teamSlug, id, name)).to.be.true;
      });

      it('fetches tag', () => {
        store.dispatch(restaurants.addNewTagToRestaurant(teamSlug, id, name));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${id}/tags`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ name }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.addNewTagToRestaurant(teamSlug, id, name)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('addTagToRestaurant', () => {
    let restaurantId;
    let id;
    beforeEach(() => {
      restaurantId = 1;
      id = 2;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches postTagToRestaurant', () => {
        const postTagToRestaurantStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('postTagToRestaurant', postTagToRestaurantStub);

        store.dispatch(restaurants.addTagToRestaurant(teamSlug, restaurantId, id));

        expect(postTagToRestaurantStub.calledWith(teamSlug, restaurantId, id)).to.be.true;
      });

      it('fetches tag', () => {
        store.dispatch(restaurants.addTagToRestaurant(teamSlug, restaurantId, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${restaurantId}/tags`);
        expect(fetchMock.lastCall()[1].body).to.eq(JSON.stringify({ id }));
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.addTagToRestaurant(teamSlug, restaurantId, id)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });

  describe('removeTagFromRestaurant', () => {
    let restaurantId;
    let id;
    beforeEach(() => {
      restaurantId = 1;
      id = 2;
    });

    describe('before fetch', () => {
      beforeEach(() => {
        fetchMock.mock('*', {});
      });

      it('dispatches deleteTagFromRestaurant', () => {
        const deleteTagFromRestaurantStub = actionCreatorStub();
        restaurantsRewireAPI.__Rewire__('deleteTagFromRestaurant', deleteTagFromRestaurantStub);

        store.dispatch(restaurants.removeTagFromRestaurant(teamSlug, restaurantId, id));

        expect(deleteTagFromRestaurantStub.calledWith(teamSlug, restaurantId, id)).to.be.true;
      });

      it('fetches tag', () => {
        store.dispatch(restaurants.removeTagFromRestaurant(teamSlug, restaurantId, id));

        expect(fetchMock.lastCall()[0]).to.eq(`/api/teams/${teamSlug}/restaurants/${restaurantId}/tags/${id}`);
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        fetchMock.mock('*', 400);
        return store.dispatch(
          restaurants.removeTagFromRestaurant(teamSlug, restaurantId, id)
        );
      });

      it('dispatches flashError', () => {
        expect(flashErrorStub.called).to.be.true;
      });
    });
  });
});
