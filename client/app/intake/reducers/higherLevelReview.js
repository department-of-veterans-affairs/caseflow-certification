import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getReceiptDateError, formatRatings, formatRelationships } from '../util';
import _ from 'lodash';

const getInformalConferenceError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.informal_conference, 0) === 'blank') && 'Please select an option.'
);

const getSameOfficeError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.same_office, 0) === 'blank') && 'Please select an option.'
);

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.HIGHER_LEVEL_REVIEW.key) {
    return state;
  }

  return update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    informalConference: {
      $set: serverIntake.informal_conference
    },
    sameOffice: {
      $set: serverIntake.same_office
    },
    receiptDate: {
      $set: serverIntake.receipt_date && formatDateStr(serverIntake.receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.receipt_date)
    },
    ratings: {
      $set: formatRatings(serverIntake.ratings)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    },
    endProductDescription: {
      $set: serverIntake.end_product_description
    },
    relationships: {
      $set: formatRelationships(serverIntake.relationships)
    }
  });
};

export const mapDataToInitialHigherLevelReview = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    receiptDate: null,
    receiptDateError: null,
    informalConference: null,
    informalConferenceError: null,
    sameOffice: null,
    sameOfficeError: null,
    claimantNotVeteran: null,
    claimant: null,
    isStarted: false,
    isReviewed: false,
    isComplete: false,
    endProductDescription: null,
    issueCount: 0,
    nonRatedIssues: { },
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const higherLevelReviewReducer = (state = mapDataToInitialHigherLevelReview(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialHigherLevelReview();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a HigherLevelReview intake is being processed
  if (!state.isStarted) {
    return state;
  }

  const selectedIssues = _(state.nonRatedIssues).
    filter((issue) => {
      return issue.category && issue.description;
    }).value().length + _(state.ratings).
      map((rating) => {
        return _.map(rating.issues, (issue) => {
          return _.merge(issue, { profile_date: rating.profile_date });
        });
      }).
      flatten().
      filter('isSelected').value().length;

  const nonRatedIssueCounter = () => {
    let descriptionCounter = !state.nonRatedIssues[action.payload.issueId].description && state.nonRatedIssues[action.payload.issueId].category ? 1 : 0
    let categoryCounter = state.nonRatedIssues[action.payload.issueId].description ? 1 : 0

    console.log("description num::", descriptionCounter)
    console.log("category num::", categoryCounter)

    if (!action.payload.category && !action.payload.description) {
      return -1
    }

    if (action.payload.description) {
      return 1
    }

    if (action.payload.category) {
      return 1
    }
  };

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialHigherLevelReview();
  case ACTIONS.SET_INFORMAL_CONFERENCE:
    return update(state, {
      informalConference: {
        $set: action.payload.informalConference
      }
    });
  case ACTIONS.SET_SAME_OFFICE:
    return update(state, {
      sameOffice: {
        $set: action.payload.sameOffice
      }
    });
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      receiptDate: {
        $set: action.payload.receiptDate
      }
    });
  case ACTIONS.SET_CLAIMANT_NOT_VETERAN:
    return update(state, {
      claimantNotVeteran: {
        $set: action.payload.claimantNotVeteran
      }
    });
  case ACTIONS.SET_CLAIMANT:
    return update(state, {
      claimant: {
        $set: action.payload.claimant
      }
    });
  case ACTIONS.SUBMIT_REVIEW_START:
    return update(state, {
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_SUCCEED:
    return updateFromServerIntake(update(state, {
      informalConferenceError: {
        $set: null
      },
      sameOfficeError: {
        $set: null
      },
      receiptDateError: {
        $set: null
      },
      isReviewed: {
        $set: true
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      informalConferenceError: {
        $set: getInformalConferenceError(action.payload.responseErrorCodes)
      },
      sameOfficeError: {
        $set: getSameOfficeError(action.payload.responseErrorCodes)
      },
      receiptDateError: {
        $set: getReceiptDateError(action.payload.responseErrorCodes, state)
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_START:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_SUCCEED:
    return updateFromServerIntake(update(state, {
      isComplete: {
        $set: true
      },
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.COMPLETE_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.FAILED
        },
        completeIntakeErrorCode: {
          $set: action.payload.responseErrorCode
        },
        completeIntakeErrorData: {
          $set: action.payload.responseErrorData
        }
      }
    });
  case ACTIONS.SET_ISSUE_SELECTED:
    return update(state, {
      ratings: {
        [action.payload.profileDate]: {
          issues: {
            [action.payload.issueId]: {
              isSelected: {
                $set: action.payload.isSelected
              }
            }
          }
        }
      },
      issueCount: {
        $set: action.payload.isSelected ? state.issueCount + 1 : state.issueCount - 1
      }
    });
  case ACTIONS.ADD_NON_RATED_ISSUE:
    return update(state, {
      nonRatedIssues: {
        [Object.keys(state.nonRatedIssues).length]: {
          $set: {
            category: null,
            description: null
          }
        }
      }
    });
  case ACTIONS.SET_ISSUE_CATEGORY:
    return update(state, {
      nonRatedIssues: {
        [action.payload.issueId]: {
          category: {
            $set: action.payload.category
          }
        }
      },
      issueCount: {
        $set: selectedIssues + nonRatedIssueCounter()
      }
    });
  case ACTIONS.SET_ISSUE_DESCRIPTION:
    return update(state, {
      nonRatedIssues: {
        [action.payload.issueId]: {
          description: {
            $set: action.payload.description
          }
        }
      },
      issueCount: {
        $set: selectedIssues + nonRatedIssueCounter()
      }
    });
  default:
    return state;
  }
};
