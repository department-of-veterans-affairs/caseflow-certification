import { ACTIONS } from './constants';
import { update } from '../util/ReducerUtil';

export const initialState = {};

const reducers = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_HEARING_SCHEDULE:
    return update(state, {
      hearingSchedule: {
        $set: action.payload.hearingSchedule
      }
    });
  case ACTIONS.RECEIVE_PAST_UPLOADS:
    return update(state, {
      pastUploads: {
        $set: action.payload.pastUploads
      }
    });
  case ACTIONS.RECEIVE_SCHEDULE_PERIOD:
    return update(state, {
      schedulePeriod: {
        $set: action.payload.schedulePeriod
      }
    });
  case ACTIONS.FILE_TYPE_CHANGE:
    return update(state, {
      fileType: {
        $set: action.payload.fileType
      }
    });
  case ACTIONS.RO_CO_START_DATE_CHANGE:
    return update(state, {
      roCoStartDate: {
        $set: action.payload.startDate
      }
    });
  case ACTIONS.RO_CO_END_DATE_CHANGE:
    return update(state, {
      roCoEndDate: {
        $set: action.payload.endDate
      }
    });
  case ACTIONS.RO_CO_FILE_UPLOAD:
    return update(state, {
      roCoFileUpload: {
        $set: action.payload.file
      }
    });
  case ACTIONS.JUDGE_START_DATE_CHANGE:
    return update(state, {
      judgeStartDate: {
        $set: action.payload.startDate
      }
    });
  case ACTIONS.JUDGE_END_DATE_CHANGE:
    return update(state, {
      judgeEndDate: {
        $set: action.payload.endDate
      }
    });
  case ACTIONS.VIEW_START_DATE_CHANGE:
    return update(state, {
      viewStartDate: {
        $set: action.payload.viewStartDate
      }
    });
  case ACTIONS.VIEW_END_DATE_CHANGE:
    return update(state, {
      viewEndDate: {
        $set: action.payload.viewEndDate
      }
    });
  case ACTIONS.JUDGE_FILE_UPLOAD:
    return update(state, {
      judgeFileUpload: {
        $set: action.payload.file
      }
    });
  case ACTIONS.TOGGLE_UPLOAD_CONTINUE_LOADING:
    return update(state, {
      $toggle: ['uploadContinueLoading']
    });
  default:
    return state;
  }
};

export default reducers;
