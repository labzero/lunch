import { BrowserHistory } from "history";
import { Team as TeamModel } from "./models";

export interface Route {

}

export interface NormalizedItems<U> {
  entities: { [index: string]: {[index: number]: U}},
  result: number[]
}

interface Record {
  id: number
}

export type RoleType = "guest" | "member" | "owner";

interface Role {
  type: RoleType,
  teamId: number,
  userId: number
}

export interface User extends Record {
  roles: Role[]
  superuser?: boolean;
  type?: RoleType
}

export interface Restaurant extends Record {
  address: string;
  all_decision_count: number | string;
  all_vote_count: number | string;
  lat: number;
  lng: number;
  name: string;
  placeId: string;
  tags: number[];
  votes: number[];
}

export interface Tag extends Record {
  restaurant_count: string | number;
}

export interface Team extends Record {
  roles?: Role[],
  slug: string
}

export interface Flash {
  id: string,
  message: string;
  type: "error" | "success"
}

export interface Vote extends Record {
  restaurantId: number;
  userId: number;
}

export interface Decision extends Record {
  restaurantId: number;
}

export interface Notification {
  actionType: Action["type"]
  id: string;
  vals: {
    decision?: Decision;
    newName?: string;
    userId: number;
  } & ({
    restaurant?: Restaurant;
  } | {
    restaurantId?: number;
  }) & ({
    tag?: Tag
  } | {
    tagId?: number;
  })
}

interface NewlyAdded {
  id: number,
  userId: number,
}

export interface StateData {
  flashes: Flash[];
  host: string;
  team: TeamModel;
  teams: TeamModel[];
  user: Express.User;
}

interface BaseState {
  restaurants: {
    didInvalidate: boolean,
    nameFilter: string,
    isFetching: boolean,
  },
  decisions: {
    isFetching: boolean,
    didInvalidate: boolean,
  },
  flashes: Flash[],
  host: string,
  notifications: Notification[],
  modals: {},
  listUi: {
    editNameFormValue?: string;
    flipMove: boolean,
    newlyAdded?: NewlyAdded
  },
  locale: 'en',
  mapUi: {
    center?: {
      lat: number;
      lng: number;
    }
    infoWindow?: {
      latLng: {
        lat: number,
        lng: number
      },
      placeId: string
    } | {
      id: number
    } | {},
    newlyAdded?: NewlyAdded
    showUnvoted: boolean,
    showPOIs: boolean,
    tempMarker?: {
      latLng: {
        lat: number,
        lng: number
      }
    }
  },
  pageUi: {},
  tagFilters: number[],
  tagExclusions: number[],
  tags: {
    isFetching: boolean,
    didInvalidate: boolean,
  },
  teams: {
    isFetching: boolean,
    didInvalidate: boolean,
  },
  users: {
    isFetching: boolean,
    didInvalidate: boolean,
  },
  wsPort: number
}

export type State = BaseState & {
  restaurants: {
    items: {
      entities: {
        restaurants: {[index: number]: Restaurant};
        votes?: {[index: number]: Vote};
      }
      result: number[]
    }
  },
  decisions: {
    items: NormalizedItems<Decision>,
  },
  tags: {
    items: NormalizedItems<Tag>
  },
  team: Team,
  teams: {
    items: NormalizedItems<Team>
  },
  user: User,
  users: {
    items: NormalizedItems<User>
  }
}

export type NonNormalizedState = BaseState & {
  decisions: {
    items: Decision[]
  }
  restaurants: {
    items: Restaurant[]
  }
  tags: {
    items: Tag[]
  }
  team: Partial<TeamModel>
  teams: {
    items: TeamModel[]
  }
  user: Express.User
  users: {
    items: User[]
  }
}

export interface StateHelpers {
  fetch?: (url: string, options: any) => Promise<any>;
  history?: BrowserHistory;
}

export interface LatLng {
  lat: number,
  lng: number
}

export type PastDecisionsOpts = {
  restaurantId: number
}

export type ConfirmOpts = {
  actionLabel: string,
  body: string,
  action: Action
}

export type Action = { type: "INVALIDATE_DECISIONS" } | {
  type: "REQUEST_DECISIONS"
} | {
  type: "POST_DECISION",
  restaurantId: number;
} | {
  type: "DELETE_DECISION",
} | {
  type: "RECEIVE_DECISIONS",
  items: Decision[];
} | {
  type: "DECISION_POSTED",
  decision: Decision,
  deselected: Decision[],
  userId: number
} | {
  type: "DECISIONS_DELETED",
  decisions: Decision[],
  userId: number
} | {
  type: "RECEIVE_RESTAURANTS",
  items: Restaurant[]
} | {
  type: "RESTAURANT_RENAMED",
  id: number,
  fields: {
    name: string
  },
  userId: number
} | {
  type: "RESTAURANT_DELETED",
  id: number,
  userId: number
} | {
  type: "RESTAURANT_POSTED",
  restaurant: Restaurant,
  userId: number
} | {
  type: "SORT_RESTAURANTS",
  decision?: Decision,
  newlyAdded?: NewlyAdded,
  user: User
} | { type: "INVALIDATE_RESTAURANTS" } | {
  type: "REQUEST_RESTAURANTS"
} | {
  type: "POST_RESTAURANT",
  restaurant: Partial<Restaurant>
} | {
  type: "DELETE_RESTAURANT",
  id: number
} | {
  type: "RENAME_RESTAURANT",
  id: number,
  restaurant: Partial<Restaurant>
} | {
  type: "POST_VOTE",
  id: number
} | {
  type: "VOTE_POSTED",
  vote: Vote
} | {
  type: "DELETE_VOTE",
  restaurantId: number,
  id: number
} | {
  type: "VOTE_DELETED",
  restaurantId: number,
  userId: number,
  id: number
} | {
  type: "POST_NEW_TAG_TO_RESTAURANT",
  restaurantId: number,
  value: string
} | {
  type: "POSTED_NEW_TAG_TO_RESTAURANT",
  restaurantId: number,
  tag: Tag,
  userId: number;
} | {
  type: "POST_TAG_TO_RESTAURANT",
  restaurantId: number,
  id: number
} | {
  type: "POSTED_TAG_TO_RESTAURANT",
  restaurantId: number,
  id: number,
  userId: number
} | {
  type: "DELETE_TAG_FROM_RESTAURANT",
  restaurantId: number,
  id: number
} | {
  type: "DELETED_TAG_FROM_RESTAURANT",
  restaurantId: number,
  id: number,
  userId: number
} | {
  type: "DELETE_TAG",
  id: number
} | {
  type: "TAG_DELETED",
  id: number,
  userId: number
} | { type: "INVALIDATE_TAGS" } | {
  type: "REQUEST_TAGS"
} | {
  type: "RECEIVE_TAGS",
  items: Tag[]
} | {
  type: "POST_TEAM",
  team: Team
} | {
  type: "TEAM_POSTED",
  team: Team
} | {
  type: "PATCH_TEAM",
  team: Team
} | {
  type: "TEAM_PATCHED",
  team: Team
} | {
  type: "DELETE_TEAM"
} | {
  type: "TEAM_DELETED"
} | {
  type: "POST_USER",
  user: User
} | {
  type: "USER_POSTED",
  user: User
} | {
  type: "PATCH_USER",
  id: number,
  isSelf: boolean,
  roleType: RoleType,
  team: Team
} | {
  type: "USER_PATCHED",
  id: number,
  isSelf: boolean,
  team: Team,
  user: User
} | {
  type: "DELETE_USER",
  id: number,
  isSelf: boolean,
  team: Team
} | {
  type: "USER_DELETED",
  id: number,
  isSelf: boolean,
  team: Team
} | {
  type: "PATCH_CURRENT_USER",
  payload: User
} | {
  type: "CURRENT_USER_PATCHED",
  user: User
} | { type: "INVALIDATE_USERS" } | {
  type: "REQUEST_USERS"
} | {
  type: "RECEIVE_USERS",
  items: User[]
} | {
  type: "ADD_TAG_EXCLUSION",
  id: number
} | {
  type: "REMOVE_TAG_EXCLUSION",
  id: number
} | { type: "CLEAR_TAG_EXCLUSIONS" } | {
  type: "ADD_TAG_FILTER",
  id: number
} | {
  type: "REMOVE_TAG_FILTER",
  id: number
} | { type: "CLEAR_TAG_FILTERS" } | {
  type: "SET_EDIT_NAME_FORM_VALUE",
  id: number,
  value: string
} | {
  type: "SHOW_EDIT_NAME_FORM",
  id: number
} | {
  type: "HIDE_EDIT_NAME_FORM",
  id: number
} | {
  type: "SET_FLIP_MOVE",
  val: boolean,
} | {
  type: "SHOW_GOOGLE_INFO_WINDOW",
  placeId: string,
  latLng: LatLng
} | {
  type: "SHOW_RESTAURANT_INFO_WINDOW",
  restaurant: Restaurant
} | {
  type: "HIDE_INFO_WINDOW"
} | {
  type: "SET_SHOW_POIS",
  val: boolean;
} | {
  type: "SET_SHOW_UNVOTED",
  val: boolean;
} | {
  type: "SET_CENTER",
  center: LatLng
} | {
  type: "CLEAR_CENTER"
} | {
  type: "CREATE_TEMP_MARKER",
  result: {
    label: string,
    latLng: LatLng
  }
} | {
  type: "CLEAR_TEMP_MARKER"
} | {
  type: "CLEAR_MAP_UI_NEWLY_ADDED"
} | {
  type: "SET_NAME_FILTER",
  val: string,
} | {
  type: "SHOW_MODAL",
  name: "pastDecisions",
  opts: PastDecisionsOpts
} | {
  type: "SHOW_MODAL",
  name: "confirm",
  opts: ConfirmOpts
} | {
  type: "HIDE_MODAL",
  name: string
} | {
  type: "NOTIFY",
  realAction: Action
} | {
  type: "EXPIRE_NOTIFICATION",
  id: string;
} | {
  id: string;
  message: string;
  type: "FLASH_ERROR";
} | {
  id: string;
  message: string;
  type: "FLASH_SUCCESS"
} | {
  id: string;
  type: "EXPIRE_FLASH"
} | {
  type: "SCROLL_TO_TOP"
} | {
  type: "SCROLLED_TO_TOP"
}

export type Reducer<T extends keyof State> = (
  state: State[T],
  action: Action
) => State[T];
