import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.SHOW_TAG_FILTER_FORM, state =>
    update(state, {
      filterForm: {
        $merge: {
          shown: true
        }
      }
    })
  ],
  [ActionTypes.HIDE_TAG_FILTER_FORM, state =>
    update(state, {
      filterForm: {
        $merge: {
          autosuggestValue: '',
          shown: false
        }
      }
    })
  ],
  [ActionTypes.SET_TAG_FILTER_AUTOSUGGEST_VALUE, (state, action) =>
    update(state, {
      filterForm: {
        $merge: {
          autosuggestValue: action.value
        }
      }
    })
  ],
  [ActionTypes.ADD_TAG_FILTER, state =>
    update(state, {
      filterForm: {
        $merge: {
          autosuggestValue: ''
        }
      }
    })
  ],
  [ActionTypes.SHOW_TAG_EXCLUSION_FORM, state =>
    update(state, {
      exclusionForm: {
        $merge: {
          shown: true
        }
      }
    })
  ],
  [ActionTypes.HIDE_TAG_EXCLUSION_FORM, state =>
    update(state, {
      exclusionForm: {
        $merge: {
          autosuggestValue: '',
          shown: false
        }
      }
    })
  ],
  [ActionTypes.SET_TAG_EXCLUSION_AUTOSUGGEST_VALUE, (state, action) =>
    update(state, {
      exclusionForm: {
        $merge: {
          autosuggestValue: action.value
        }
      }
    })
  ],
  [ActionTypes.ADD_TAG_EXCLUSION, state =>
    update(state, {
      exclusionForm: {
        $merge: {
          autosuggestValue: ''
        }
      }
    })
  ]
]);
