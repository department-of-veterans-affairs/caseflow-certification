import { ACTIONS } from '../constants';
import { applyCommonReducers } from '../../intake/reducers/common';
import { REQUEST_STATE } from '../../intake/constants';
import { update } from '../../util/ReducerUtil';
import { formatRequestIssues, formatRatings } from '../../intake/util/issues';
import { formatRelationships } from '../../intake/util';

export const mapDataToInitialState = function(props = {}) {
  const { serverIntake } = props;

  serverIntake.ratings = formatRatings(serverIntake.ratings);
  serverIntake.relationships = formatRelationships(serverIntake.relationships);

  return {
    ...serverIntake,
    addIssuesModalVisible: false,
    nonRatedIssueModalVisible: false,
    unidentifiedIssuesModalVisible: false,
    addedIssues: formatRequestIssues(serverIntake.requestIssues),
    originalIssues: formatRequestIssues(serverIntake.requestIssues),
    requestStatus: {
      submitIssues: REQUEST_STATE.NOT_STARTED
    },
    submitIssuesErrorCode: null
  };
};

export const intakeEditReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.REQUEST_ISSUES_UPDATE_START:
    return update(state, {
      requestStatus: {
        submitIssues: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED:
    return update(state, {
      requestStatus: {
        submitIssues: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      },
      submitIssuesErrorCode: { $set: null }
    });
  case ACTIONS.REQUEST_ISSUES_UPDATE_FAIL:
    return update(state, {
      requestStatus: {
        submitIssues: {
          $set: REQUEST_STATE.FAILED
        }
      },
      submitIssuesErrorCode: { $set: action.payload.responseErrorCode }
    });
  default:
    return applyCommonReducers(state, action);
  }
};
