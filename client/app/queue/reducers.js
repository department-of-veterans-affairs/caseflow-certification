import { combineReducers } from 'redux';
import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import * as Constants from './actionTypes';

export const initialState = {
  loadedQueueId: null,
  didLoadQueueFail: false,
  loadedQueue: {
    appeals: [],
    tasks: []
  },
  showSearchBar: false,
  filterCriteria: {
    searchQuery: ''
  }
};

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
    case Constants.RECEIVE_QUEUE_DETAILS:
      return update(state, {
        loadedQueue: {
          appeals: {
            $set: action.payload.appeals.data
          },
          tasks: {
            $set: action.payload.tasks.data
          }
        }
      });
    case Constants.RECEIVE_QUEUE_DETAILS_FAILURE:
      return update(state, {
        didLoadQueueFail: {
          $set: action.payload.failedToLoad
        }
      });
    case Constants.SET_LOADED_QUEUE_ID:
      return update(state, {
        loadedQueueId: {
          $set: action.payload.id
        }
      });
    case Constants.SHOW_SEARCH_BAR:
      return update(state, { showSearchBar: { $set: true } });
    case Constants.HIDE_SEARCH_BAR:
      return update(state, { showSearchBar: { $set: false } });
    case Constants.SET_SEARCH:
      return update(state, {
        filterCriteria: {
          searchQuery: {
            $set: action.payload.searchQuery
          }
        }
      });
    case Constants.CLEAR_SEARCH:
      return update(state, {
        filterCriteria: {
          searchQuery: {
            $set: ''
          }
        }
      });
    default:
      return state;
  }
};

const rootReducer = combineReducers({
  workQueueReducer
});

/* todo: passing rootReducer gives following error:
   Unexpected keys "loadedQueueId", "didLoadQueueFail", "loadedQueue"
   found in previous state received by the reducer. Expected to find one
   of the known reducer keys instead: "workQueueReducer". Unexpected
   keys will be ignored */
export default timeFunction(
  // rootReducer,
  workQueueReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
