/* eslint-disable max-lines */
import * as Constants from './constants';
import _ from 'lodash';
import { update } from '../util/ReducerUtil';
import { moveModel } from './utils';
import { timeFunction } from '../util/PerfDebug';
import { hideErrorMessage, showErrorMessage, updateFilteredDocIds } from './helpers/reducerHelper';

const openAnnotationDeleteModalFor = (state, annotationId) =>
  update(state, {
    ui: {
      deleteAnnotationModalIsOpenFor: {
        $set: annotationId
      }
    }
  });

const initialShowErrorMessageState = {
  tag: false,
  category: false,
  annotation: false
};

export const initialState = {
  initialDataLoadingFail: false,
  didLoadAppealFail: false,
  initialCaseLoadingFail: false,
  placingAnnotationIconPageCoords: null,
  openedAccordionSections: [
    'Categories', 'Issue tags', Constants.COMMENT_ACCORDION_KEY
  ],
  ui: {
    pendingAnnotations: {},
    pendingEditingAnnotations: {},
    selectedAnnotationId: null,
    deleteAnnotationModalIsOpenFor: null,
    placedButUnsavedAnnotation: null,
    pdf: {
      pdfsReadyToShow: {},
      isPlacingAnnotation: false,
      hidePdfSidebar: false,
      jumpToPageNumber: null
    },
    pdfSidebar: {
      showErrorMessage: initialShowErrorMessageState
    }
  },
  pages: {},
  pdfDocuments: {},
  text: [],
  documentSearchString: null,
  documentSearchIndex: 0,
  extractedText: {},

  /**
   * `editingAnnotations` is an object of annotations that are currently being edited.
   * When a user starts editing an annotation, we copy it from `annotations` to `editingAnnotations`.
   * To commit the edits, we copy from `editingAnnotations` back into `annotations`.
   * To discard the edits, we delete from `editingAnnotations`.
   */
  editingAnnotations: {}
};

export const reducer = (state = initialState, action = {}) => {
  let allTags;
  let uniqueTags;

  switch (action.type) {
  case Constants.COLLECT_ALL_TAGS_FOR_OPTIONS:
    allTags = Array.prototype.concat.apply([], _(action.payload).
      map((doc) => {
        return doc.tags ? doc.tags : [];
      }).
      value());
    uniqueTags = _.uniqWith(allTags, _.isEqual);

    return update(
      state,
      {
        ui: {
          tagOptions: {
            $set: uniqueTags
          }
        }
      }
    );
  case Constants.REQUEST_INITIAL_DATA_FAILURE:
    return update(state, {
      initialDataLoadingFail: {
        $set: action.payload.value
      }
    });
  case Constants.REQUEST_INITIAL_CASE_FAILURE:
    return update(state, {
      initialCaseLoadingFail: {
        $set: action.payload.value
      }
    });
  case Constants.RECEIVE_MANIFESTS:
    return update(state, {
      ui: {
        manifestVbmsFetchedAt: {
          $set: action.payload.manifestVbmsFetchedAt
        },
        manifestVvaFetchedAt: {
          $set: action.payload.manifestVvaFetchedAt
        }
      }
    });
  case Constants.RECEIVE_APPEAL_DETAILS_FAILURE:
    return update(state,
      {
        didLoadAppealFail: {
          $set: action.payload.failedToLoad
        }
      }
    );
  case Constants.SET_SORT:
    return updateFilteredDocIds(update(state, {
      ui: {
        docFilterCriteria: {
          sort: {
            sortBy: {
              $set: action.payload.sortBy
            },
            sortAscending: {
              $apply: (prevVal) => !prevVal
            }
          }
        }
      }
    }));
  case Constants.CLEAR_ALL_PDF_VIEWER_ERRORS:
    return update(state, {
      ui: {
        pdfSidebar: { showErrorMessage: { $set: initialShowErrorMessageState } }
      }
    });
  case Constants.HIDE_ERROR_MESSAGE:
    return update(hideErrorMessage(state, action.payload.messageType));
  case Constants.SHOW_ERROR_MESSAGE:
    return update(showErrorMessage(state, action.payload.messageType));
  case Constants.REQUEST_NEW_TAG_CREATION:
    return update(hideErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $push: action.payload.newTags
          }
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return update(showErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) =>
              _.differenceBy(
                tags,
                action.payload.tagsThatWereAttemptedToBeCreated,
                'text'
              )
          }
        }
      }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_SUCCESS:
    return update(
      state,
      {
        documents: {
          [action.payload.docId]: {
            tags: {

              /**
               * We can't just `$set: action.payload.createdTags` here, because that may wipe out additional tags
               * that have been created on the client since this new tag was created. Consider the following sequence
               * of events:
               *
               *  1) REQUEST_NEW_TAG_CREATION (newTag = 'first')
               *  2) REQUEST_NEW_TAG_CREATION (newTag = 'second')
               *  3) REQUEST_NEW_TAG_CREATION_SUCCESS (newTag = 'first')
               *
               * At this point, the doc tags are [{text: 'first'}, {text: 'second'}].
               * Action (3) gives us [{text: 'first}]. If we just do a `$set`, we'll end up with:
               *
               *  [{text: 'first'}]
               *
               * and we've erroneously erased {text: 'second'}. To fix this, we'll do a merge instead. If we have tags
               * that have not yet been saved on the server, but we see those tags in action.payload.createdTags, we'll
               * merge it in. If the pending tag does not have a corresponding saved tag in action.payload.createdTags,
               * we'll leave it be.
               */
              $apply: (docTags) => _.map(docTags, (docTag) => {
                if (docTag.id) {
                  return docTag;
                }

                const createdTag = _.find(action.payload.createdTags, _.pick(docTag, 'text'));

                if (createdTag) {
                  return createdTag;
                }

                return docTag;
              })
            }
          }
        }
      }
    );
  case Constants.ROTATE_PDF_DOCUMENT: {
    const rotation = (_.get(state.documents, [action.payload.docId, 'rotation'], 0) +
      Constants.ROTATION_INCREMENTS) % Constants.COMPLETE_ROTATION;

    return update(
      state,
      {
        documents: {
          [action.payload.docId]: {
            rotation: {
              $set: rotation
            }
          }
        }
      }
    );
  }
  case Constants.JUMP_TO_PAGE:
    return update(
      state,
      {
        ui: {
          pdf: {
            $merge: {
              jumpToPageNumber: action.payload.pageNumber
            }
          }
        }
      }
    );
  case Constants.RESET_JUMP_TO_PAGE:
    return update(
      state,
      {
        ui: {
          pdf: {
            $merge: {
              jumpToPageNumber: null
            }
          }
        }
      }
    );
  case Constants.REQUEST_REMOVE_TAG:
    return update(state, {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => {
              const removedTagIndex = _.findIndex(tags, { id: action.payload.tagId });

              return update(tags, {
                [removedTagIndex]: {
                  $merge: {
                    pendingRemoval: true
                  }
                }
              });
            }
          }
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return update(hideErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => _.reject(tags, { id: action.payload.tagId })
          }
        }
      }
    });
  case Constants.OPEN_ANNOTATION_DELETE_MODAL:
    return openAnnotationDeleteModalFor(state, action.payload.annotationId);
  case Constants.CLOSE_ANNOTATION_DELETE_MODAL:
    return openAnnotationDeleteModalFor(state, null);
  case Constants.REQUEST_DELETE_ANNOTATION:
    return update(
      hideErrorMessage(openAnnotationDeleteModalFor(state, null), 'annotation'),
      {
        editingAnnotations: {
          [action.payload.annotationId]: {
            $apply: (annotation) => annotation && {
              ...annotation,
              pendingDeletion: true
            }
          }
        },
        annotations: {
          [action.payload.annotationId]: {
            $merge: {
              pendingDeletion: true
            }
          }
        }
      }
    );
  case Constants.REQUEST_DELETE_ANNOTATION_FAILURE:
    return update(showErrorMessage(state, 'annotation'), {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $unset: 'pendingDeletion'
        }
      },
      annotations: {
        [action.payload.annotationId]: {
          $unset: 'pendingDeletion'
        }
      }
    });
  case Constants.REQUEST_DELETE_ANNOTATION_SUCCESS:
    return update(
      state,
      {
        editingAnnotations: {
          $unset: action.payload.annotationId
        },
        annotations: {
          $unset: action.payload.annotationId
        }
      }
    );
  case Constants.REQUEST_MOVE_ANNOTATION:
    return update(hideErrorMessage(state, 'annotation'), {
      ui: {
        pendingEditingAnnotations: {
          [action.payload.annotation.id]: {
            $set: action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_MOVE_ANNOTATION_SUCCESS:
    return moveModel(
      state,
      ['ui', 'pendingEditingAnnotations'],
      ['annotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_MOVE_ANNOTATION_FAILURE:
    return update(showErrorMessage(state, 'annotation'), {
      ui: {
        pendingEditingAnnotations: {
          $unset: action.payload.annotationId
        }
      }
    });
  case Constants.PLACE_ANNOTATION:
    return update(state, {
      ui: {
        placedButUnsavedAnnotation: {
          $set: {
            ...action.payload,
            class: 'Annotation',
            type: 'point'
          }
        },
        pdf: {
          isPlacingAnnotation: { $set: false }
        }
      }
    });
  case Constants.START_PLACING_ANNOTATION:
    return update(state, {
      ui: {
        pdf: {
          isPlacingAnnotation: { $set: true }
        }
      },
      openedAccordionSections: {
        $apply: (sectionKeys) => _.union(sectionKeys, [Constants.COMMENT_ACCORDION_KEY])
      }
    });
  case Constants.SHOW_PLACE_ANNOTATION_ICON:
    return update(state, {
      placingAnnotationIconPageCoords: {
        $set: {
          pageIndex: action.payload.pageIndex,
          ...action.payload.pageCoords
        }
      }
    });
  case Constants.STOP_PLACING_ANNOTATION:
    return update(state, {
      placingAnnotationIconPageCoords: {
        $set: null
      },
      ui: {
        placedButUnsavedAnnotation: { $set: null },
        pdf: {
          isPlacingAnnotation: { $set: false }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION:
    return update(hideErrorMessage(state, 'annotation'), {
      ui: {
        placedButUnsavedAnnotation: { $set: null },
        pendingAnnotations: {
          [action.payload.annotation.id]: {
            $set: action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION_SUCCESS:
    return update(state, {
      ui: {
        pendingAnnotations: {
          $unset: action.payload.annotationTemporaryId
        }
      },
      annotations: {
        [action.payload.annotation.id]: {
          $set: {
            // These two duplicate fields exist on annotations throughout the app.
            // I am not sure why this is, but we'll patch it here to make everything work.
            document_id: action.payload.annotation.documentId,
            uuid: action.payload.annotation.id,

            ...action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION_FAILURE:
    return update(showErrorMessage(state, 'annotation'), {
      ui: {
        // This will cause a race condition if the user has created multiple annotations.
        // Whichever annotation failed most recently is the one that'll be in the
        // "new annotation" text box. For now, I think that's ok.
        placedButUnsavedAnnotation: {
          $set: state.ui.pendingAnnotations[action.payload.annotationTemporaryId]
        },
        pendingAnnotations: {
          $unset: action.payload.annotationTemporaryId
        }
      }
    });
  case Constants.START_EDIT_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $set: state.annotations[action.payload.annotationId]
        }
      }
    });
  case Constants.CANCEL_EDIT_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        $unset: action.payload.annotationId
      }
    });
  case Constants.UPDATE_ANNOTATION_CONTENT:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          comment: {
            $set: action.payload.content
          }
        }
      }
    });
  case Constants.UPDATE_NEW_ANNOTATION_CONTENT:
    return update(state, {
      ui: {
        placedButUnsavedAnnotation: {
          comment: {
            $set: action.payload.content
          }
        }
      }
    });
  case Constants.REQUEST_EDIT_ANNOTATION:
    return moveModel(
      hideErrorMessage(state, 'annotation'),
      ['editingAnnotations'],
      ['ui', 'pendingEditingAnnotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_EDIT_ANNOTATION_SUCCESS:
    return moveModel(
      hideErrorMessage(state, 'annotation'),
      ['ui', 'pendingEditingAnnotations'],
      ['annotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_EDIT_ANNOTATION_FAILURE:
    return moveModel(
      showErrorMessage(state, 'annotation'),
      ['ui', 'pendingEditingAnnotations'],
      ['editingAnnotations'],
      action.payload.annotationId
    );
  case Constants.SELECT_ANNOTATION:
    return update(state, {
      ui: {
        selectedAnnotationId: {
          $set: action.payload.annotationId
        }
      }
    });
  case Constants.SCROLL_TO_SIDEBAR_COMMENT:
    return update(state, {
      ui: {
        pdf: {
          scrollToSidebarComment: { $set: action.payload.scrollToSidebarComment }
        }
      }
    });
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(showErrorMessage(state, 'tag'), {
      documents: {
        [action.payload.docId]: {
          tags: {
            $apply: (tags) => {
              const removedTagIndex = _.findIndex(tags, { id: action.payload.tagId });

              return update(tags, {
                [removedTagIndex]: {
                  $merge: {
                    pendingRemoval: false
                  }
                }
              });
            }
          }
        }
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { scrollToComment: { $set: action.payload.scrollToComment } } }
    });
  case Constants.TOGGLE_PDF_SIDEBAR:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdf: {
            hidePdfSidebar: !state.ui.pdf.hidePdfSidebar
          }
        }
      }
    );
  case Constants.SET_OPENED_ACCORDION_SECTIONS:
    return update(
      state,
      {
        openedAccordionSections: {
          $set: action.payload.openedAccordionSections
        }
      }
    );
  case Constants.SET_UP_PDF_PAGE:
    return update(
      state,
      {
        pages: {
          [`${action.payload.file}-${action.payload.pageIndex}`]: {
            $set: action.payload.page
          }
        }
      }
    );
  case Constants.CLEAR_PDF_PAGE: {
    // We only want to remove the page and container if we're cleaning up the same page that is
    // currently stored here. This is to avoid a race condition where a user returns to this
    // page and the new page object is stored here before we have a chance to destroy the
    // old object.
    const FILE_PAGE_INDEX = `${action.payload.file}-${action.payload.pageIndex}`;

    if (action.payload.page &&
      _.get(state.pages, [FILE_PAGE_INDEX, 'page']) === action.payload.page) {
      return update(
        state,
        {
          pages: {
            [FILE_PAGE_INDEX]: {
              $merge: {
                page: null,
                container: null
              }
            }
          }
        }
      );
    }

    return state;
  }
  case Constants.SET_PDF_DOCUMENT:
    return update(
      state,
      {
        pdfDocuments: {
          [action.payload.file]: {
            $set: action.payload.doc
          }
        }
      }
    );
  case Constants.CLEAR_PDF_DOCUMENT:
    if (action.payload.doc && _.get(state.pdfDocuments, [action.payload.file]) === action.payload.doc) {
      return update(
        state,
        {
          pdfDocuments: {
            [action.payload.file]: {
              $set: null
            }
          }
        });
    }

    return state;
  case Constants.GET_DOCUMENT_TEXT:
    return update(
      state,
      {
        extractedText: {
          $merge: action.payload.textObject
        }
      }
    );
  case Constants.ZERO_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $set: 0
        }
      }
    );
  case Constants.UPDATE_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $apply: (index) => action.payload.increment ? index + 1 : index - 1
        }
      }
    );
  default:
    return state;
  }
};

export default timeFunction(
  reducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
