import { Reducer } from '../interfaces';

export { default as decisions } from './decisions';
export { default as flashes } from './flashes';
export { default as listUi } from './listUi';
export { default as mapUi } from './mapUi';
export { default as modals } from './modals';
export { default as notifications } from './notifications';
export { default as pageUi } from './pageUi';
export { default as restaurants } from './restaurants';
export { default as tagExclusions } from './tagExclusions';
export { default as tagFilters } from './tagFilters';
export { default as tags } from './tags';
export { default as team } from './team';
export { default as teams } from './teams';
export { default as user } from './user';
export { default as users } from './users';

export const host: Reducer<"host"> = (state) => state;
export const locale: Reducer<"locale"> = (state) => state;
export const wsPort: Reducer<"wsPort"> = (state) => state;
