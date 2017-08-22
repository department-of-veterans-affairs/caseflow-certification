import { CategoryIcon } from '../components/RenderFunctions';
import React from 'react';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';
export const TOGGLE_DOCUMENT_CATEGORY_FAIL = 'TOGGLE_DOCUMENT_CATEGORY_FAIL';
export const RECEIVE_DOCUMENTS = 'RECEIVE_DOCUMENTS';
export const RECEIVE_ANNOTATIONS = 'RECEIVE_ANNOTATIONS';
export const RECEIVE_ASSIGNMENTS = 'RECEIVE_ASSIGNMENTS';
export const RECEIVE_APPEAL_DETAILS = 'RECEIVE_APPEAL_DETAILS';
export const RECEIVE_APPEAL_DETAILS_FAILURE = 'RECEIVE_APPEAL_DETAILS_FAILURE';
export const REQUEST_INITIAL_DATA_FAILURE = 'INITIAL_DATA_LOADING_FAIL';
export const REQUEST_INITIAL_CASE_FAILURE = 'INITIAL_CASE_LOADING_FAIL';
export const TOGGLE_FILTER_DROPDOWN = 'TOGGLE_FILTER_DROPDOWN';
export const SET_CATEGORY_FILTER = 'SET_CATEGORY_FILTER';
export const SET_TAG_FILTER = 'SET_TAG_FILTER';
export const CLEAR_CATEGORY_FILTER = 'CLEAR_CATEGORY_FILTER';
export const CLEAR_TAG_FILTER = 'CLEAR_TAG_FILTER';
export const ADD_NEW_TAG = 'ADD_NEW_TAG';
export const REMOVE_TAG = 'REMOVE_TAG';
export const REQUEST_NEW_TAG_CREATION_SUCCESS = 'REQUEST_NEW_TAG_CREATION_SUCCESS';
export const REQUEST_NEW_TAG_CREATION_FAILURE = 'REQUEST_NEW_TAG_CREATION_FAILURE';
export const REQUEST_NEW_TAG_CREATION = 'REQUEST_NEW_TAG_CREATION';
export const REQUEST_REMOVE_TAG = 'REQUEST_REMOVE_TAG';
export const REQUEST_REMOVE_TAG_SUCCESS = 'REQUEST_REMOVE_TAG_SUCCESS';
export const REQUEST_REMOVE_TAG_FAILURE = 'REQUEST_REMOVE_TAG_FAILURE';
export const SELECT_CURRENT_VIEWER_PDF = 'SELECT_CURRENT_VIEWER_PDF';
export const SHOW_NEXT_PDF = 'SHOW_NEXT_PDF';
export const SHOW_PREV_PDF = 'SHOW_PREV_PDF';
export const SCROLL_TO_COMMENT = 'SCROLL_TO_COMMENT';
export const TOGGLE_COMMENT_LIST = 'TOGGLE_COMMENT_LIST';
export const TOGGLE_PDF_SIDEBAR = 'TOGGLE_PDF_SIDEBAR';
export const LAST_READ_DOCUMENT = 'LAST_READ_DOCUMENT';
export const SCROLL_TO_SIDEBAR_COMMENT = 'SCROLL_TO_SIDEBAR_COMMENT';
export const COLLECT_ALL_TAGS_FOR_OPTIONS = 'COLLECT_ALL_TAGS_FOR_OPTIONS';
export const SET_SORT = 'SET_SORT';
export const SET_PDF_READY_TO_SHOW = 'SET_PDF_READY_TO_SHOW';
export const SET_SEARCH = 'SET_SEARCH';
export const CLEAR_ALL_FILTERS = 'CLEAR_ALL_FILTERS';
export const CLEAR_ALL_SEARCH = 'CLEAR_ALL_SEARCH';
export const SET_DOC_LIST_SCROLL_POSITION = 'SET_DOC_LIST_SCROLL_POSITION';
export const JUMP_TO_PAGE = 'JUMP_TO_PAGE';
export const RESET_JUMP_TO_PAGE = 'RESET_JUMP_TO_PAGE';

export const OPEN_ANNOTATION_DELETE_MODAL = 'OPEN_ANNOTATION_DELETE_MODAL';
export const CLOSE_ANNOTATION_DELETE_MODAL = 'CLOSE_ANNOTATION_DELETE_MODAL';
export const REQUEST_DELETE_ANNOTATION = 'REQUEST_DELETE_ANNOTATION';
export const REQUEST_DELETE_ANNOTATION_SUCCESS = 'REQUEST_DELETE_ANNOTATION_SUCCESS';
export const REQUEST_DELETE_ANNOTATION_FAILURE = 'REQUEST_DELETE_ANNOTATION_FAILURE';
export const REQUEST_CREATE_ANNOTATION = 'REQUEST_CREATE_ANNOTATION';
export const REQUEST_CREATE_ANNOTATION_SUCCESS = 'REQUEST_CREATE_ANNOTATION_SUCCESS';
export const REQUEST_CREATE_ANNOTATION_FAILURE = 'REQUEST_CREATE_ANNOTATION_FAILURE';
export const REQUEST_MOVE_ANNOTATION = 'REQUEST_MOVE_ANNOTATION';
export const REQUEST_MOVE_ANNOTATION_SUCCESS = 'REQUEST_MOVE_ANNOTATION_SUCCESS';
export const REQUEST_MOVE_ANNOTATION_FAILURE = 'REQUEST_MOVE_ANNOTATION_FAILURE';
export const START_EDIT_ANNOTATION = 'START_EDIT_ANNOTATION';
export const UPDATE_ANNOTATION_CONTENT = 'UPDATE_ANNOTATION_CONTENT';
export const UPDATE_NEW_ANNOTATION_CONTENT = 'UPDATE_NEW_ANNOTATION_CONTENT';
export const CANCEL_EDIT_ANNOTATION = 'CANCEL_EDIT_ANNOTATION';
export const REQUEST_EDIT_ANNOTATION = 'REQUEST_EDIT_ANNOTATION';
export const REQUEST_EDIT_ANNOTATION_SUCCESS = 'REQUEST_EDIT_ANNOTATION_SUCCESS';
export const REQUEST_EDIT_ANNOTATION_FAILURE = 'REQUEST_EDIT_ANNOTATION_FAILURE';
export const START_PLACING_ANNOTATION = 'START_PLACING_ANNOTATION';
export const PLACE_ANNOTATION = 'PLACE_ANNOTATION';
export const SHOW_PLACE_ANNOTATION_ICON = 'SHOW_PLACE_ANNOTATION_ICON';
export const HIDE_PLACE_ANNOTATION_ICON = 'HIDE_PLACE_ANNOTATION_ICON';
export const STOP_PLACING_ANNOTATION = 'STOP_PLACING_ANNOTATION';
export const SELECT_ANNOTATION = 'SELECT_ANNOTATION';
export const SET_PAGE_COORD_BOUNDS = 'SET_PAGE_COORD_BOUNDS';

export const SET_OPENED_ACCORDION_SECTIONS = 'SET_OPENED_ACCORDION_SECTIONS';
export const SET_VIEWING_DOCUMENTS_OR_COMMENTS = 'SET_VIEWING_DOCUMENTS_OR_COMMENTS';

export const COMMENT_ACCORDION_KEY = 'Comments';

// case select related constants
export const RECEIVE_APPEALS_USING_VETERAN_ID = 'RECEIVE_APPEALS_USING_VETERAN_ID';
export const CASE_SELECT_APPEAL = 'CASE_SELECT_APPEAL';
export const SET_CASE_SELECT_SEARCH = 'SET_CASE_SELECT_SEARCH';
export const CLEAR_SELECTED_APPEAL = 'CLEAR_SELECTED_APPEAL';
export const CLEAR_CASE_SELECT_SEARCH = 'CLEAR_CASE_SELECT_SEARCH';
export const CLEAR_RECEIVED_APPEALS = 'CLEAR_RECEIVED_APPEALS';

export const DOCUMENTS_OR_COMMENTS_ENUM = {
  DOCUMENTS: 'documents',
  COMMENTS: 'comments'
};

// If we used CSS in JS, we wouldn't have to keep this value in sync with the CSS in a brittle way.
export const ANNOTATION_ICON_SIDE_LENGTH = 40;

export const MOVE_ANNOTATION_ICON_DIRECTIONS = {
  LEFT: 'LEFT',
  RIGHT: 'RIGHT',
  UP: 'UP',
  DOWN: 'DOWN'
};

export const documentCategories = {
  procedural: {
    renderOrder: 0,
    humanName: 'Procedural',
    svg: <CategoryIcon color="#5A94EC" />
  },
  medical: {
    renderOrder: 1,
    humanName: 'Medical',
    svg: <CategoryIcon color="#FF6868" />
  },
  other: {
    renderOrder: 2,
    humanName: 'Other Evidence',
    svg: <CategoryIcon color="#3AD2CF" />
  },
  case_summary: {
    renderOrder: 3,
    humanName: 'Case Summary',
    svg: <CategoryIcon color="#FDC231" />,
    readOnly: true
  }
};

// colors
export const READER_COLOR = '#417505';
