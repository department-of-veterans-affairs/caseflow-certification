import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';
import _ from 'lodash';
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';
import { combineReducers } from 'redux';

export const initialState = {
  loadedQueue: {
    appeals: [],
    tasks: []
  }
};

const mapArrayToObjectById = (collection, attrs) => _(collection).
  map((item) => ([
    item.id, _.extend({}, item, attrs)
  ])).
  fromPairs().
  value();

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      loadedQueue: {
        appeals: {
          $set: mapArrayToObjectById(action.payload.appeals, { docCount: 0 })
        },
        tasks: {
          $set: mapArrayToObjectById(action.payload.tasks)
        }
      }
    });
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return update(state, {
      loadedQueue: {
        appeals: {
          [action.payload.appealId]: {
            $set: {
              docCount: action.payload.docCount
            }
          }
        }
      }
    });
  default:
    return state;
  }
};

const rootReducer = combineReducers({
  queue: workQueueReducer,
  caseSelect: caseSelectReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
