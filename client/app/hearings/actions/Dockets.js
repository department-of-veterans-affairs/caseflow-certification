import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, ACTIONS, debounceMs } from '../analytics';
import moment from 'moment';
import { now } from '../util/DateUtil';

export const populateWorksheet = (worksheet) => ({
  type: Constants.POPULATE_WORKSHEET,
  payload: {
    worksheet
  }
});

export const handleWorksheetServerError = (err) => ({
  type: Constants.HANDLE_WORKSHEET_SERVER_ERROR,
  payload: {
    err
  }
});

export const fetchingWorksheet = () => ({
  type: Constants.FETCHING_WORKSHEET
});

export const getWorksheet = (id) => (dispatch) => {
  dispatch(fetchingWorksheet());

  ApiUtil.get(`/hearings/${id}/worksheet.json`, { cache: true }).
    then((response) => {
      dispatch(populateWorksheet(response.body));
    }, (err) => {
      dispatch(handleWorksheetServerError(err));
    });
};

export const onRepNameChange = (repName) => ({
  type: Constants.SET_REPNAME,
  payload: {
    repName
  }
});

export const onWitnessChange = (witness) => ({
  type: Constants.SET_WITNESS,
  payload: {
    witness
  }
});

export const setHearingPrepped = (payload, gaCategory = CATEGORIES.HEARINGS_DAYS_PAGE, submitToGA = true) => ({
  type: Constants.SET_HEARING_PREPPED,
  payload,
  ...submitToGA && {
    meta: {
      analytics: {
        category: gaCategory,
        action: ACTIONS.DOCKET_HEARING_PREPPED,
        label: payload.prepped ? 'checked' : 'unchecked'
      }
    }
  }
});

export const onMilitaryServiceChange = (militaryService) => ({
  type: Constants.SET_MILITARY_SERVICE,
  payload: {
    militaryService
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
    }
  }
});

export const onSummaryChange = (summary) => ({
  type: Constants.SET_SUMMARY,
  payload: {
    summary
  },
  meta: {
    analytics: {
      category: CATEGORIES.HEARING_WORKSHEET_PAGE,
      debounceMs
    }
  }
});

export const toggleWorksheetSaving = (saving) => ({
  type: Constants.TOGGLE_WORKSHEET_SAVING,
  payload: {
    saving
  }
});

export const setWorksheetTimeSaved = (timeSaved) => ({
  type: Constants.SET_WORKSHEET_TIME_SAVED,
  payload: {
    timeSaved
  }
});

export const setWorksheetSaveFailedStatus = (saveFailed) => ({
  type: Constants.SET_WORKSHEET_SAVE_FAILED_STATUS,
  payload: {
    saveFailed
  }
});

export const saveWorksheet = (worksheet) => (dispatch) => {
  if (!worksheet.edited) {
    dispatch(setWorksheetTimeSaved(now()));

    return;
  }

  dispatch(toggleWorksheetSaving(true));
  dispatch(setWorksheetSaveFailedStatus(false));

  ApiUtil.patch(`/hearings/worksheets/${worksheet.external_id}`, { data: { worksheet } }).
    then(() => {
      dispatch({ type: Constants.SET_WORKSHEET_EDITED_FLAG_TO_FALSE });
    },
    () => {
      dispatch(setWorksheetSaveFailedStatus(true));
      dispatch(toggleWorksheetSaving(false));
    }).
    finally(() => {
      dispatch(setWorksheetTimeSaved(now()));
      dispatch(toggleWorksheetSaving(false));
    });
};

export const setPrepped = (hearingId, hearingExternalId, prepped, date) => (dispatch) => {
  const payload = {
    hearingId,
    prepped,
    date: moment(date).format('YYYY-MM-DD'),
    setEdited: false
  };

  dispatch(setHearingPrepped(payload,
    CATEGORIES.HEARING_WORKSHEET_PAGE));

  let data = { hearing: { prepped } };

  ApiUtil.patch(`/hearings/${hearingExternalId}`, { data }).
    then(() => {
      // request was successful
    },
    () => {
      payload.prepped = !prepped;

      // request failed, resetting value
      dispatch(setHearingPrepped(payload, CATEGORIES.HEARING_WORKSHEET_PAGE, false));
    });
};
