// External Dependencies
import { createSelector } from '@reduxjs/toolkit';
import { mapValues, chain, values, memoize } from 'lodash';

// Local Dependencies
import { escapeRegExp, loadAppeal, documentsView } from 'utils/reader';

/**
 * Selector for the Filtered Doc IDs
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Filtered Doc IDs
 */
export const filteredDocIdState = (state) => state.documentList.filteredDocIds;

/**
 * Selector for the Documents
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents
 */
export const documentState = (state) => state.documents;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const editingAnnotationState = (state) => state.annotationLayer.editingAnnotations;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const pendingEditingAnnotationState = (state) => state.annotationLayer.pendingEditingAnnotations;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const annotationState = (state) => state.annotationLayer.annotations;

/**
 * Selector for the Editing Annotation State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Editing Annotation State
 */
export const pendingAnnotationState = (state) => state.annotationLayer.pendingAnnotations;

/**
 * Selector that returns the text Pages are currently filtered by
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- Returns an Array of Page ids that match the current search :text
 */
export const searchTermState = (state) => state.searchAction.searchTerm;

/**
 * Selector for the Extracted Text State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Extracted Text State
 */
export const extractedTextState = (state) => state.searchAction.extractedText;

/**
 * Selector for the File State
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The File State
 */
export const fileState = (state, props) => props.file;

/**
 * Selector for the Document Filter Criteria
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The File State
 */
export const docFilterCriteriaState = (state) => state.documentList.docFilterCriteria;

/**
 * Selector for the Selected Index
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The File State
 */
export const selectedIndexState = (state) => state.searchAction.matchIndex;

/**
 * Filtered Documents state
 */
export const filteredDocuments = createSelector(
  [filteredDocIdState, documentState],
  (filteredDocIds, allDocs) => filteredDocIds ? filteredDocIds.map((docId) => allDocs[docId]) : values(allDocs)
);

/**
 * Annotation State Filtered by Document ID
 */
export const annotationStateByDocId = createSelector(
  [editingAnnotationState, pendingEditingAnnotationState, annotationState, pendingAnnotationState],
  (editingAnnotations, pendingEditingAnnotations, annotations, pendingAnnotations) => memoize((docId) =>
    chain(editingAnnotations).
      values().
      map((annotation) => ({
        editing: true,
        ...annotation
      })).
      concat(values(pendingEditingAnnotations), values(annotations), values(pendingAnnotations)).
      uniqBy('id').
      reject('pendingDeletion').
      filter({ documentId: docId }).
      value()
  )
);

/**
 * Annotation State for each Document
 */
export const annotationStatePerDocument = createSelector(
  [filteredDocuments, annotationStateByDocId],
  (documents, filterAnnotationState) => mapValues(documents, (doc) => filterAnnotationState(doc.id))
);

/**
 * Document List Filtered State
 */
export const docListIsFiltered = createSelector(
  [documentState, filteredDocIdState, docFilterCriteriaState],
  (documents, filteredDocIds, docFilterCriteria) =>
    Boolean(
      documents.length !== filteredDocIds.length ||
      docFilterCriteria.searchQuery ||
      values(docFilterCriteria.category).some() ||
      values(docFilterCriteria.tag).some()
    )
);

/**
 * Text within a file State
 */
export const textForFile = createSelector(
  [extractedTextState, fileState],
  (extractedText, file) => extractedText.filter((pageText) => pageText.file === file)
);

/**
 * Matches Per Page State
 */
export const matchesPerPage = createSelector(
  [textForFile, searchTermState],
  (text, searchTerm) => text.
    map((page) => ({
      id: page.id,
      pageIndex: page.pageIndex,
      matches: (page.text.match(new RegExp(escapeRegExp(searchTerm), 'gi')) || []).length
    })).
    filter((page) => page.matches > 0)
);

/**
 * Total Count of Pages with Matching text State
 */
export const totalMatches = createSelector(
  [matchesPerPage],
  (matches) => matches.map((match) => match.matches).sum()
);

/**
 * Index of the Currently Selected File that matches the search text State
 */
export const currentMatchIndex = createSelector(
  [totalMatches, selectedIndexState],
  (totalMatchesInFile, selectedIndex) => (selectedIndex + totalMatchesInFile) % totalMatchesInFile
);

/**
 * State for the Document List Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents List State
 */
export const documentListScreen = (state) => ({
  // annotationsPerDocument: annotationStatePerDocument(state.reader),
  documentsView: documentsView(
    Object.values(state.reader.documents.list),
    state.reader.documentList.docFilterCriteria,
    state.reader.documentList.viewingDocumentsOrComments
  ),
  searchCategoryHighlights: state.reader.documentList.searchCategoryHighlights,
  loadedAppealId: state.reader.pdfViewer.loadedAppealId,
  tagOptions: state.reader.pdfViewer.tagOptions,
  filterCriteria: state.reader.documentList.docFilterCriteria,
  documents: filteredDocuments(state.reader),
  caseSelectedAppeal: state.reader.caseSelect.selectedAppeal,
  manifestVbmsFetchedAt: state.reader.documentList.manifestVbmsFetchedAt,
  manifestVvaFetchedAt: state.reader.documentList.manifestVvaFetchedAt,
  queueRedirectUrl: state.reader.documentList.queueRedirectUrl,
  queueTaskType: state.reader.documentList.queueTaskType,
  documentFilters: state.reader.documentList.pdfList.filters,
  storeDocuments: state.reader.documents.list,
  isPlacingAnnotation: state.reader.annotationLayer.isPlacingAnnotation,
  appeal: loadAppeal(
    state.reader.caseSelect.assignments,
    state.reader.pdfViewer.loadedAppealId,
    state.reader.pdfViewer.loadedAppeal
  )
});

/**
 * State for the Document Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Document State
 */
export const documentScreen = (state) => ({
  documents: filteredDocuments(state.reader),
  documentFilters: state.reader.documentList.pdfList.filters,
  storeDocuments: state.reader.documents,
  isPlacingAnnotation: state.reader.annotationLayer.isPlacingAnnotation,
  appeal: state.reader.pdfViewer.loadedAppeal,
  annotations: state.reader.annotationLayer.annotations,
  pdf: state.reader.pdf,
  pdfViewer: state.reader.pdf,
  annotationLayer: state.reader.annotationLayer,
});
