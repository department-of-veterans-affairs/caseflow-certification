import React, { PropTypes } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import AnnotationStorage from '../util/AnnotationStorage';
import ApiUtil from '../util/ApiUtil';
import * as ReaderActions from './actions';
import _ from 'lodash';

const PARALLEL_DOCUMENT_REQUESTS = 3;

export class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    let selectedLabels = {
      decisions: false,
      layperson: false,
      privateMedical: false,
      procedural: false,
      vaMedial: false,
      veteranSubmitted: false
    };

    this.state = {
      // We want to show the list view (currentPdfIndex null), unless
      // there is just a single pdf in which case we want to just show
      // the first pdf.
      currentPdfIndex: this.props.appealDocuments.length > 1 ? null : 0,
      filterBy: '',
      isCommentLabelSelected: false,
      selectedLabels,
      sortBy: 'date',
      sortDirection: 'ascending',
      unsortedDocuments: this.props.appealDocuments.map((doc) => {
        doc.receivedAt = doc.received_at;

        return doc;
      })
    };

    this.props.onReceiveDocs(this.props.appealDocuments);

    this.annotationStorage = new AnnotationStorage(this.props.annotations);

    this.state.documents = this.filterDocuments(
      this.sortDocuments(this.state.unsortedDocuments));
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.appealDocuments !== nextProps.appealDocuments) {
      this.props.onReceiveDocs(nextProps.appealDocuments);
    }
  }

  documentUrl = (doc) => {
    return `/document/${doc.id}/pdf`;
  }

  showPdf = (pdfId) => (event) => {
    // If the user is trying to open the link in a new tab/window
    // then follow the link. Otherwise if they just clicked the link
    // keep them contained within the SPA.
    // ctrlKey for windows
    // shift key for opening in new window
    // metaKey for Macs
    // button for middle click
    if (event.ctrlKey ||
        event.shiftKey ||
        event.metaKey ||
        (event.button &&
        event.button === 1)) {

      this.markAsRead(pdfId);

      return true;
    }

    event.preventDefault();
    this.props.selectCurrentPdf(pdfId);
  }

  markAsRead = (pdfId) => {
    // For some reason calling this synchronosly prevents the new
    // tab from opening. Move it to an asynchronus call.
    setTimeout(() =>
      this.props.handleSetLastRead(pdfId)
    );

    ApiUtil.patch(`/document/${pdfId}/mark-as-read`).
      catch(() => {
        /* eslint-disable no-console */
        console.log('Error marking as read');
        /* eslint-enable no-console */
      });
  }

  onShowList = () => {
    this.props.unselectPdf();
  }

  sortAndFilter = () => {
    this.setState({
      documents: this.filterDocuments(
        this.sortDocuments(this.state.unsortedDocuments))
    });
  }

  sortDocuments = (documents) => {
    let documentCopy = [...documents];
    let multiplier;

    if (this.state.sortDirection === 'ascending') {
      multiplier = 1;
    } else if (this.state.sortDirection === 'descending') {
      multiplier = -1;
    } else {
      return;
    }

    documentCopy.sort((doc1, doc2) => {
      if (this.state.sortBy === 'date') {
        return multiplier * (new Date(doc1.receivedAt) - new Date(doc2.receivedAt));
      } else if (this.state.sortBy === 'type') {
        return multiplier * (doc1.type < doc2.type ? -1 : 1);
      }

      return 0;

    });

    return documentCopy;
  }

  componentDidMount = () => {
    let downloadDocuments = (documentUrls, index) => {
      if (index >= documentUrls.length) {
        return;
      }

      ApiUtil.get(documentUrls[index], { cache: true }).
        then(() => {
          downloadDocuments(documentUrls, index + PARALLEL_DOCUMENT_REQUESTS);
        });
    };

    for (let i = 0; i < PARALLEL_DOCUMENT_REQUESTS; i++) {
      downloadDocuments(this.props.appealDocuments.map((doc) => {
        return this.documentUrl(doc);
      }), i);
    }
  }

  metadataContainsString = (doc, searchString) => {
    if (doc.type.toLowerCase().includes(searchString)) {
      return true;
    } else if (doc.receivedAt.toLowerCase().includes(searchString)) {
      return true;
    }
  }

  // This filters documents to those that contain the search text
  // in either the metadata (type, date) or in the comments
  // on the document.
  filterDocuments = (documents) => {
    let filterBy = this.state.filterBy.toLowerCase();
    let labelsSelected = Object.keys(this.state.selectedLabels).
      reduce((anySelected, label) =>
        anySelected || this.state.selectedLabels[label], false);

    let filteredDocuments = documents.filter((doc) => {
      // if there is a label selected, we filter on that.
      if (labelsSelected && !this.state.selectedLabels[doc.label]) {
        return false;
      }

      let annotations = this.annotationStorage.getAnnotationByDocumentId(doc.id);

      if (this.state.isCommentLabelSelected && annotations.length === 0) {
        return false;
      }

      if (this.metadataContainsString(doc, filterBy)) {
        return true;
      }

      if (annotations.some((annotation) => annotation.comment.
        toLowerCase().includes(filterBy))) {
        return true;
      }

      return false;
    });

    return filteredDocuments;
  }

  onFilter = (filterBy) => {
    this.setState({
      filterBy
    }, this.sortAndFilter);
  }

  onLabelSelected = (label) => () => {
    let selectedLabels = { ...this.state.selectedLabels };

    selectedLabels[label] = !selectedLabels[label];
    this.setState({
      selectedLabels
    }, this.sortAndFilter);
  }

  selectComments = () => {
    this.setState({
      isCommentLabelSelected: !this.state.isCommentLabelSelected
    }, this.sortAndFilter);
  }

  onJumpToComment = (comment) => () => {
    this.props.selectCurrentPdf(comment.documentId);
    this.props.onScrollToComment(comment);
  }

  onCommentScrolledTo = () => {
    this.props.onScrollToComment(null);
  }

  render() {
    const documents = _.map(this.props.filteredDocIds, (docId) => this.props.storeDocuments[docId]) ||
      _.values(this.props.storeDocuments);
    const shouldRenderPdf = this.props.currentRenderedFile !== null;

    const activeDocIndex = _.findIndex(documents, { id: this.props.currentRenderedFile });
    const activeDoc = documents[activeDocIndex];

    const nextDocExists = activeDocIndex + 1 < _.size(documents);
    const nextDocId = nextDocExists && documents[activeDocIndex + 1].id;

    const previousDocExists = activeDocIndex > 0;
    const prevDocId = previousDocExists && documents[activeDocIndex - 1].id;

    return (
      <div className="section--document-list">
        {!shouldRenderPdf && <PdfListView
          annotationStorage={this.annotationStorage}
          documents={documents}
          showPdf={this.showPdf}
          showPdfAndJumpToPage={this.showPdfAndJumpToPage}
          numberOfDocuments={this.props.appealDocuments.length}
          onFilter={this.onFilter}
          filterBy={this.state.filterBy}
          sortBy={this.state.sortBy}
          selectedLabels={this.state.selectedLabels}
          selectLabel={this.onLabelSelected}
          selectComments={this.selectComments}
          isCommentLabelSelected={this.state.isCommentLabelSelected}
          onJumpToComment={this.onJumpToComment} />}
        {shouldRenderPdf && <PdfViewer
          addNewTag={this.props.addNewTag}
          removeTag={this.props.removeTag}
          showTagErrorMsg={this.props.ui.pdfSidebar.showTagErrorMsg}
          annotationStorage={this.annotationStorage}
          file={this.documentUrl(activeDoc)}
          doc={activeDoc}
          nextDocId={nextDocId}
          prevDocId={prevDocId}
          onShowList={this.onShowList}
          pdfWorker={this.props.pdfWorker}
          onJumpToComment={this.onJumpToComment}
          onCommentScrolledTo={this.onCommentScrolledTo} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string,
  onScrollToComment: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  handleSetLastRead: PropTypes.func.isRequired
};

const mapStateToProps = (state) => {
  return {
    ui: {
      pdfSidebar: {
        showTagErrorMsg: state.ui.pdfSidebar.showTagErrorMsg
      }
    },
    currentRenderedFile: state.ui.pdf.currentRenderedFile,
    documentFilters: state.ui.pdfList.filters,
    filteredDocIds: state.ui.filteredDocIds,
    storeDocuments: state.documents
  };
};

const mapDispatchToProps = (dispatch) => {
  return bindActionCreators(ReaderActions, dispatch);
};

export default connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer);
