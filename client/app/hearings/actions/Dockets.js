import * as Constants from '../constants/constants';

export const populateDockets = (dockets) => ({
  type: Constants.POPULATE_DOCKETS,
  payload: {
    dockets
  }
});

export const populateWorksheet = (worksheet) => ({
  type: Constants.POPULATE_WORKSHEET,
  payload: {
    worksheet
  }
});

export const handleServerError = (err) => ({
  type: Constants.HANDLE_SERVER_ERROR,
  payload: {
    err
  }
});

export const setNotes = (hearingIndex, notes, date) => ({
  type: Constants.SET_NOTES,
  payload: {
    hearingIndex,
    notes,
    date
  }
});

export const setDisposition = (hearingIndex, disposition, date) => ({
  type: Constants.SET_DISPOSITION,
  payload: {
    hearingIndex,
    disposition,
    date
  }
});

export const setHoldOpen = (hearingIndex, holdOpen, date) => ({
  type: Constants.SET_HOLD_OPEN,
  payload: {
    hearingIndex,
    holdOpen,
    date
  }
});

export const setAod = (hearingIndex, aod, date) => ({
  type: Constants.SET_AOD,
  payload: {
    hearingIndex,
    aod,
    date
  }
});

export const setAddOn = (hearingIndex, addOn, date) => ({
  type: Constants.SET_ADD_ON,
  payload: {
    hearingIndex,
    addOn,
    date
  }
});

export const setTranscriptRequested = (hearingIndex, transcriptRequested, date) => ({
  type: Constants.SET_TRANSCRIPT_REQUESTED,
  payload: {
    hearingIndex,
    transcriptRequested,
    date
  }
});

export const onContentionsChange = (contentions) => ({
  type: Constants.SET_CONTENTIONS,
  payload: {
    contentions
  }
});

export const onWorksheetPeriodsChange = (worksheetPeriods) => ({
  type: Constants.SET_WORKSHEET_PERIODS,
  payload: {
    worksheetPeriods
  }
});

export const onEvidenceChange = (evidence) => ({
  type: Constants.SET_EVIDENCE,
  payload: {
    evidence
  }
});

export const onWorksheetCommentsChange = (worksheetComments) => ({
  type: Constants.SET_WORKSHEET_COMMENTS,
  payload: {
    worksheetComments
  }
});
