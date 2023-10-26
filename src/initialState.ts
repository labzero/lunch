import { host, port } from "./config";
import { NonNormalizedState, StateData } from "./interfaces";

const getInitialState = (): NonNormalizedState => ({
  restaurants: {
    didInvalidate: true,
    nameFilter: "",
    isFetching: false,
    items: [],
  },
  decisions: {
    isFetching: false,
    didInvalidate: true,
    items: [],
  },
  flashes: [],
  host,
  notifications: [],
  modals: {},
  listUi: {
    flipMove: true,
  },
  mapUi: {
    infoWindow: {},
    showUnvoted: true,
    showPOIs: false,
  },
  pageUi: {},
  tagFilters: [],
  tagExclusions: [],
  tags: {
    isFetching: false,
    didInvalidate: true,
    items: [],
  },
  team: null,
  teams: {
    isFetching: false,
    didInvalidate: true,
    items: [],
  },
  user: null,
  users: {
    isFetching: false,
    didInvalidate: true,
    items: [],
  },
  port: module.hot ? port : 0,
});

export default (stateData: StateData) => {
  const initialState = getInitialState();
  if (stateData.teams) {
    initialState.teams.items = stateData.teams.map((t) => t.toJSON());
    initialState.teams.didInvalidate = false;
  }
  if (stateData.user) {
    initialState.user = stateData.user;
  }
  if (stateData.team) {
    initialState.team = stateData.team;
  }
  if (stateData.host) {
    initialState.host = stateData.host;
  }
  if (stateData.flashes) {
    initialState.flashes = stateData.flashes;
  }
  return initialState;
};
