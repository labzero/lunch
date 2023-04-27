import update from 'immutability-helper';
import { Reducer } from '../interfaces';
import setOrMerge from './helpers/setOrMerge';

const modals: Reducer<"modals"> = (state, action) => {
  switch(action.type) {
    case "SHOW_MODAL": {
      return update(state, {
        $merge: {
          [action.name]: {
            shown: true,
            ...action.opts
          }
        }
      })
    }
    case "HIDE_MODAL": {
      return update(state, {
        $apply: (target: typeof state) => setOrMerge(target, action.name, { shown: false })
      })
    }
  }
  return state;
};

export default modals;
