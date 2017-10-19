import { ACTIONS, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import _ from 'lodash';

const formatAppeals = (appeals) => {
  return _.map(appeals, (appeal) => (
    {
      issues: appeal.issues.map(
        ({ description, program_description, note }) => ({
          description,
          programDescription: program_description,
          note
        })
      )
    }
  ));
};

const updateStateWithSavedIntake = (state, intake) => {
  return update(state, {
    veteran: {
      name: {
        $set: intake.veteran_name
      },
      formName: {
        $set: intake.veteran_form_name
      },
      fileNumber: {
        $set: intake.veteran_file_number
      }
    },
    rampElection: {
      intakeId: {
        $set: intake.id
      },
      noticeDate: {
        $set: intake.notice_date && formatDateStr(intake.notice_date)
      },
      optionSelected: {
        $set: intake.option_selected
      },
      receiptDate: {
        $set: intake.receipt_date && formatDateStr(intake.receipt_date)
      },
      isReviewed: {
        $set: Boolean(intake.option_selected && intake.receipt_date)
      },
      isComplete: {
        $set: Boolean(intake.completed_at)
      }
    },
    appeals: {
      $set: formatAppeals(intake.appeals)
    }
  });
};

export const mapDataToInitialState = (data = { currentIntake: {} }) => (
  updateStateWithSavedIntake({
    veteran: {
      name: '',
      formName: '',
      fileNumber: ''
    },
    inputs: {
      fileNumberSearch: '',
      receiptDateStr: '',
      veteranResponse: null
    },
    requestStatus: {
      fileNumberSearch: REQUEST_STATE.NOT_STARTED,
      submitReview: REQUEST_STATE.NOT_STARTED,
      completeIntake: REQUEST_STATE.NOT_STARTED,
      cancelIntake: REQUEST_STATE.NOT_STARTED
    },
    rampElection: {
      intakeId: null,
      noticeDate: null,
      optionSelected: null,
      optionSelectedError: null,
      receiptDate: null,
      receiptDateError: null,
      isReviewed: false,
      isComplete: false,
      finishConfirmed: false,
      finishConfirmedError: null
    },
    cancelModalVisible: false,
    searchError: null
  }, data.currentIntake)
);

const getOptionSelectedError = (responseErrorCodes) => (
  _.get(responseErrorCodes.option_selected, 0) && 'Please select an option.'
);

const getReceiptDateError = (responseErrorCodes, state) => (
  {
    blank:
      'Please enter a valid receipt date.',
    in_future:
      'Receipt date cannot be in the future.',
    before_notice_date: 'Receipt date cannot be earlier than the election notice ' +
      `date of ${state.rampElection.noticeDate}`
  }[_.get(responseErrorCodes.receipt_date, 0)]
);

// The keys in this object need to be snake_case
// because they're being matched to server response values.
const searchErrors = {
  invalid_file_number: {
    title: 'Veteran ID not found',
    body: 'Please enter a valid Veteran ID and try again.'
  },
  veteran_not_found: {
    title: 'Veteran ID not found',
    body: 'Please enter a valid Veteran ID and try again.'
  },
  veteran_not_accessible: {
    title: 'You don\'t have permission to view this veteran\'s information​',
    body: 'Please enter a valid Veteran ID and try again.'
  },
  did_not_receive_ramp_election: {
    title: 'No opt-in letter was sent to this veteran',
    body: "An opt-in letter was not sent to this Veteran, so this form can't be processed. " +
      'Please enter a valid Veteran ID below.'
  },
  default: {
    title: 'Something went wrong',
    body: 'Please try again. If the problem persists, please contact Caseflow support.'
  }
};

export const reducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialState();
  case ACTIONS.SET_FILE_NUMBER_SEARCH:
    return update(state, {
      inputs: {
        fileNumberSearch: {
          $set: action.payload.fileNumber
        }
      }
    });
  case ACTIONS.SET_OPTION_SELECTED:
    return update(state, {
      rampElection: {
        optionSelected: {
          $set: action.payload.optionSelected
        }
      }
    });
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      rampElection: {
        receiptDate: {
          $set: action.payload.receiptDate
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_START:
    return update(state, {
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateStateWithSavedIntake(update(state, {
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.FILE_NUMBER_SEARCH_FAIL:
    return update(state, {
      searchError: {
        $set: searchErrors[action.payload.errorCode] || searchErrors.default
      },
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.FAILED
        }
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
    return update(state, {
      rampElection: {
        isReviewed: {
          $set: true
        }
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      rampElection: {
        optionSelectedError: {
          $set: getOptionSelectedError(action.payload.responseErrorCodes)
        },
        receiptDateError: {
          $set: getReceiptDateError(action.payload.responseErrorCodes, state)
        }
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  case ACTIONS.CONFIRM_FINISH_INTAKE:
    return update(state, {
      rampElection: {
        finishConfirmed: {
          $set: action.payload.isConfirmed
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_NOT_CONFIRMED:
    return update(state, {
      rampElection: {
        finishConfirmedError: {
          $set: "You must confirm you've completed the steps"
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
    return update(state, {
      rampElection: {
        isComplete: {
          $set: true
        }
      },
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  case ACTIONS.CANCEL_INTAKE_START:
    return update(state, {
      requestStatus: {
        cancelIntake: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.CANCEL_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        cancelIntake: {
          $set: REQUEST_STATE.FAILED
        }
      },
      $toggle: ['cancelModalVisible']
    });
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return update(mapDataToInitialState(), {
      requestStatus: {
        cancelIntake: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.TOGGLE_CANCEL_MODAL:
    return update(state, {
      $toggle: ['cancelModalVisible']
    });
  default:
    return state;
  }
};
