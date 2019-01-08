import { ACTIONS } from '../constants';
import { applyCommonReducers } from '../../intake/reducers/common';
import { REQUEST_STATE } from '../../intake/constants';
import { update } from '../../util/ReducerUtil';
import { formatRequestIssues, formatContestableIssues } from '../../intake/util/issues';
import { formatRelationships } from '../../intake/util';

export const mapDataToInitialState = function(props = {}) {
  const { serverIntake, claimId, featureToggles } = props;

  serverIntake.relationships = formatRelationships(serverIntake.relationships);
  serverIntake.contestableIssues = formatContestableIssues(serverIntake.contestableIssuesByDate);

  return {
    ...serverIntake,
    claimId,
    featureToggles,
    addIssuesModalVisible: false,
    nonRatingRequestIssueModalVisible: false,
    unidentifiedIssuesModalVisible: false,
    activeNonratingRequestIssues: formatRequestIssues(serverIntake.activeNonratingRequestIssues),
    addedIssues: formatRequestIssues(serverIntake.requestIssues, serverIntake.contestableIssues),
    originalIssues: formatRequestIssues(serverIntake.requestIssues, serverIntake.contestableIssues),
    requestStatus: {
      requestIssuesUpdate: REQUEST_STATE.NOT_STARTED
    },
    requestIssuesUpdateErrorCode: null,
    issuesAfter: null,
    issuesBefore: null
  };
};

export const intakeEditReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.REQUEST_ISSUES_UPDATE_START:
    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED:
    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      },
      requestIssuesUpdateErrorCode: { $set: null },
      issuesAfter: {
        $set: formatRequestIssues(action.payload.issuesAfter)
      },
      issuesBefore: {
        $set: formatRequestIssues(action.payload.issuesBefore)
      }
    });
  case ACTIONS.REQUEST_ISSUES_UPDATE_FAIL:
    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.FAILED
        }
      },
      requestIssuesUpdateErrorCode: { $set: action.payload.responseErrorCode }
    });
  default:
    return applyCommonReducers(state, action);
  }
};
