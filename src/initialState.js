import { port } from './config';

const initialState = {
  restaurants: {
    isFetching: false,
    didInvalidate: false,
    items: []
  },
  tags: {
    isFetching: false,
    didInvalidate: false,
    items: []
  },
  decision: {
    isFetching: false,
    didInvalidate: false,
    inst: null
  },
  flashes: [],
  notifications: [],
  modals: {},
  user: {},
  users: {
    items: []
  },
  whitelistEmails: {
    isFetching: false,
    didInvalidate: false,
    items: []
  },
  latLng: {
    lat: parseFloat(process.env.SUGGEST_LAT),
    lng: parseFloat(process.env.SUGGEST_LNG)
  },
  listUi: {},
  mapUi: {
    showUnvoted: true
  },
  tagFilters: [],
  tagExclusions: [],
  tagUi: {
    filterForm: {},
    exclusionForm: {}
  },
  team: {},
  pageUi: {},
  whitelistEmailUi: {},
  wsPort: process.env.BS_RUNNING ? port : 0
};

export default (stateData) => {
  if (stateData.restaurants) {
    initialState.restaurants.items = stateData.restaurants.map(r => r.toJSON());
  }
  if (stateData.tags) {
    initialState.tags.items = stateData.tags.map(t => t.toJSON());
  }
  if (stateData.team) {
    initialState.team = stateData.team;
  }
  if (stateData.decision) {
    initialState.decision.inst = stateData.decision.toJSON();
  }
  if (stateData.user) {
    initialState.user = stateData.user;
  }
  if (stateData.users) {
    initialState.users.items = stateData.users.map(u => u.toJSON());
  }
  if (stateData.whitelistEmails) {
    initialState.whitelistEmails.items = stateData.whitelistEmails.map(w => w.toJSON());
  }
  return initialState;
};
