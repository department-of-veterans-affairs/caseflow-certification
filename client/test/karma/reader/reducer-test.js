import { expect } from 'chai';
import reducer from '../../../app/reader/reducer';
import * as Constants from '../../../app/reader/constants';

describe('Reader reducer', () => {

  const reduceActions = (actions, state) => actions.reduce(reducer, reducer(state, {}));

  describe(Constants.REQUEST_CREATE_ANNOTATION_FAILURE, () => {
    const getContext = () => {
      const annotationTemporaryId = 'some-guid';
      const annotation = {
        comment: 'text',
        id: annotationTemporaryId
      };

      return {
        state: reduceActions([
          {
            type: Constants.REQUEST_CREATE_ANNOTATION,
            payload: {
              annotation
            }
          },
          {
            type: Constants.REQUEST_CREATE_ANNOTATION_FAILURE,
            payload: {
              annotationTemporaryId
            }
          }
        ]),
        annotation
      };
    };

    it('shows an error message when creating the annotation fails', () => {
      const { state, annotation } = getContext();

      expect(state.ui.pdfSidebar.showErrorMessage.annotation).to.equal(true);
      expect(state.ui.placedButUnsavedAnnotation).to.deep.equal(annotation);
    });

    it('hides the error message when a second request is started', () => {
      const { state } = getContext();

      const nextState = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation: {
              comment: 'a second annotation',
              id: 'some-other-guid'
            }
          }
        }
      ], state);

      expect(nextState.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
    });
  });

  describe(Constants.REQUEST_DELETE_ANNOTATION_FAILURE, () => {
    const getContext = () => {
      const annotationActualId = 800;
      const annotationTemporaryId = 'some-guid';
      const annotation = {
        comment: 'text',
        id: annotationTemporaryId
      };
      const stateAfterDeleteRequest = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation
          }
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              id: annotationActualId
            },
            annotationTemporaryId
          }
        },
        {
          type: Constants.REQUEST_DELETE_ANNOTATION,
          payload: {
            annotationId: annotationActualId
          }
        }]);

      return {
        stateAfterDeleteRequest,
        stateAfterDeleteFailure: reduceActions([
          {
            type: Constants.REQUEST_DELETE_ANNOTATION_FAILURE,
            payload: {
              annotationId: annotationActualId
            }
          }
        ], stateAfterDeleteRequest),
        annotationId: annotationActualId
      };
    };

    it('marks an annotation as pending deletion', () => {
      const { stateAfterDeleteRequest, annotationId } = getContext();

      expect(stateAfterDeleteRequest.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
      expect(stateAfterDeleteRequest.annotations[annotationId].pendingDeletion).to.equal(true);
    });

    it('shows an error message when the request fails', () => {
      const { stateAfterDeleteFailure, annotationId } = getContext();

      expect(stateAfterDeleteFailure.ui.pdfSidebar.showErrorMessage.annotation).to.equal(true);
      expect(stateAfterDeleteFailure.annotations[annotationId].pendingDeletion).to.equal(undefined);
    });
  });

  describe(Constants.REQUEST_CREATE_ANNOTATION_SUCCESS, () => {
    it('updates annotations when the server save is successful', () => {
      const docId = 3;
      const annotationId = 100;
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: [{
            id: docId,
            tags: []
          }]
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation: {
              documentId: docId,
              comment: 'annotation text'
            }
          }
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              id: annotationId,
              documentId: docId,
              comment: 'annotation text'
            }
          }
        }
      ]);

      expect(state.ui.pendingAnnotations).to.deep.equal({});
      expect(state.annotations).to.deep.equal({
        [annotationId]: {
          id: annotationId,
          uuid: annotationId,
          documentId: docId,
          document_id: docId,
          comment: 'annotation text'
        }
      });

      const nextAnnotationId = 200;
      const stateWithNextAnnotation = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation: {
              documentId: docId,
              comment: 'next annotation text'
            }
          }
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              id: nextAnnotationId,
              documentId: docId,
              comment: 'next annotation text'
            }
          }
        }
      ], state);

      expect(stateWithNextAnnotation.annotations).to.deep.equal({
        [annotationId]: {
          id: annotationId,
          uuid: annotationId,
          documentId: docId,
          document_id: docId,
          comment: 'annotation text'
        },
        [nextAnnotationId]: {
          id: nextAnnotationId,
          uuid: nextAnnotationId,
          documentId: docId,
          document_id: docId,
          comment: 'next annotation text'
        }
      });
    });
  });

  describe(Constants.REQUEST_NEW_TAG_CREATION_SUCCESS, () => {
    it('successfully merges tags', () => {
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: [{
            id: 0,
            tags: []
          }]
        },
        {
          type: Constants.REQUEST_NEW_TAG_CREATION,
          payload: {
            newTags: [{ text: 'first tag' }],
            docId: 0
          }
        },
        {
          type: Constants.REQUEST_NEW_TAG_CREATION,
          payload: {
            newTags: [{ text: 'second tag' }],
            docId: 0
          }
        },
        {
          type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
          payload: {
            createdTags: [{
              text: 'first tag',
              id: 100
            }],
            docId: 0
          }
        }
      ]);

      expect(state.documents[0].tags).to.deep.equal([
        {
          text: 'first tag',
          id: 100
        },
        {
          text: 'second tag'
        }
      ]);
    });
  });
});
