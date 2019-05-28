/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/
import update from 'immutability-helper';
import * as Constants from '../constants';
import _ from 'lodash';

// TODO move to issue reducer
export const newHearingIssueState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, {
    worksheetIssues: {
      [action.payload.issueId]: spec
    }
  });
};

export const newHearingWorksheetState = (state, action, spec) => {
  _.extend(spec, { edited: { $set: true } });

  return update(state, { worksheet: spec });
};

export const hearingsReducer = function(state = {}, action = {}) {
  switch (action.type) {
  case Constants.POPULATE_WORKSHEET: {
    const worksheetAppeals = _.keyBy(action.payload.worksheet.appeals_ready_for_hearing, 'id');
    let worksheetIssues = _(worksheetAppeals).flatMap('worksheet_issues').
      keyBy('id').
      value();

    if (_.isEmpty(worksheetIssues)) {
      worksheetIssues = _.keyBy(action.payload.worksheet.worksheet_issues, 'id');
    }

    const worksheet = _.omit(action.payload.worksheet, ['appeals_ready_for_hearing']);

    return update(state, {
      worksheetIssues: { $set: worksheetIssues },
      worksheetAppeals: { $set: worksheetAppeals },
      worksheet: { $set: worksheet }
    });
  }

  case Constants.SET_HEARING_DAY_HEARINGS:
    return update(state, {
      hearings: { $set: action.payload.hearings }
    });

  case Constants.SET_REPNAME:
    return newHearingWorksheetState(state, action, { representative_name: { $set: action.payload.repName } });

  case Constants.SET_WITNESS:
    return newHearingWorksheetState(state, action, { witness: { $set: action.payload.witness } });

  case Constants.SET_SUMMARY:
    return newHearingWorksheetState(state, action, { summary: { $set: action.payload.summary } });

  case Constants.SET_MILITARY_SERVICE:
    return newHearingWorksheetState(state, action, {
      military_service: { $set: action.payload.militaryService }
    });
  case Constants.SET_HEARING_PREPPED:
    return update(state, {
      hearings: {
        [action.payload.hearingExternalId]: {
          prepped: { $set: action.payload.prepped }
        }
      }
    });

  case Constants.SET_ISSUE_NOTES:
    return newHearingIssueState(state, action, { notes: { $set: action.payload.notes } });

  case Constants.SET_WORKSHEET_ISSUE_NOTES:
    return newHearingIssueState(state, action, { worksheet_notes: { $set: action.payload.notes } });

  case Constants.SET_ISSUE_DISPOSITION:
    return newHearingIssueState(state, action, { disposition: { $set: action.payload.disposition } });

  case Constants.SET_DESCRIPTION:
    return newHearingIssueState(state, action, { description: { $set: action.payload.description } });

  case Constants.SET_REOPEN:
    return newHearingIssueState(state, action, { reopen: { $set: action.payload.reopen } });

  case Constants.SET_ALLOW:
    return newHearingIssueState(state, action, { allow: { $set: action.payload.allow } });

  case Constants.SET_DENY:
    return newHearingIssueState(state, action, { deny: { $set: action.payload.deny } });

  case Constants.SET_REMAND:
    return newHearingIssueState(state, action, { remand: { $set: action.payload.remand } });

  case Constants.SET_DISMISS:
    return newHearingIssueState(state, action, { dismiss: { $set: action.payload.dismiss } });

  case Constants.SET_OMO:
    return newHearingIssueState(state, action, { omo: { $set: action.payload.omo } });

  case Constants.TOGGLE_ISSUE_DELETE_MODAL:
    return newHearingIssueState(state, action, { isShowingModal: { $set: action.payload.isShowingModal } });

  case Constants.ADD_ISSUE:
    return update(state, {
      worksheetIssues: { [action.payload.issue.id]: {
        $set: action.payload.issue
      } }
    });

  case Constants.DELETE_ISSUE:
    return newHearingIssueState(state, action, { _destroy: { $set: true } });

  case Constants.TOGGLE_WORKSHEET_SAVING:
    return update(state, { worksheetIsSaving: { $set: action.payload.saving }
    });

  case Constants.SET_WORKSHEET_TIME_SAVED:
    return update(state, { worksheetTimeSaved: { $set: action.payload.timeSaved }
    });

  case Constants.SET_WORKSHEET_SAVE_FAILED_STATUS:
    return update(state, {
      saveWorksheetFailed: { $set: action.payload.saveFailed }
    });

  case Constants.SET_ISSUE_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheetIssues: {
        [action.payload.issueId]: { edited: { $set: false } }
      }
    });

  case Constants.SET_WORKSHEET_EDITED_FLAG_TO_FALSE:
    return update(state, {
      worksheet: { edited: { $set: false } }
    });

  default: return state;
  }
};

export default hearingsReducer;
