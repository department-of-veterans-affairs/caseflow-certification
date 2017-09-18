/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';

import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { bindActionCreators } from 'redux';
import { isUserEditingText, pageNumberOfPageIndex, pageIndexOfPageNumber,
  pageCoordsOfRootCoords } from '../reader/utils';
import PdfPage from '../reader/PdfPage';
import { connect } from 'react-redux';
import _ from 'lodash';
import { setPdfReadyToShow,
  placeAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon,
  onScrollToComment } from '../reader/actions';
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { INTERACTION_TYPES } from '../reader/analytics';

/**
 * We do a lot of work with coordinates to render PDFs.
 * It is important to keep the various coordinate systems straight.
 * Here are the systems we use:
 *
 *    Root coordinates: The coordinate system for the entire app.
 *      (0, 0) is the top left hand corner of the entire HTML document that the browser has rendered.
 *
 *    Page coordinates: A coordinate system for a given PDF page.
 *      (0, 0) is the top left hand corner of that PDF page.
 *
 * The relationship between root and page coordinates is defined by where the PDF page is within the whole app,
 * and what the current scale factor is.
 *
 * All coordinates in our codebase should have `page` or `root` in the name, to make it clear which
 * coordinate system they belong to. All converting between coordinate systems should be done with
 * the proper helper functions.
 */
export const getInitialAnnotationIconPageCoords = (iconPageBoundingBox, scrollWindowBoundingRect, scale) => {
  const leftBound = Math.max(scrollWindowBoundingRect.left, iconPageBoundingBox.left);
  const rightBound = Math.min(scrollWindowBoundingRect.right, iconPageBoundingBox.right);
  const topBound = Math.max(scrollWindowBoundingRect.top, iconPageBoundingBox.top);
  const bottomBound = Math.min(scrollWindowBoundingRect.bottom, iconPageBoundingBox.bottom);

  const rootCoords = {
    x: _.mean([leftBound, rightBound]),
    y: _.mean([topBound, bottomBound])
  };

  const pageCoords = pageCoordsOfRootCoords(rootCoords, iconPageBoundingBox, scale);

  const annotationIconOffset = ANNOTATION_ICON_SIDE_LENGTH / 2;

  return {
    x: pageCoords.x - annotationIconOffset,
    y: pageCoords.y - annotationIconOffset
  };
};

const COVER_SCROLL_HEIGHT = 120;

const TIMEOUT_FOR_GET_DOCUMENT = 100;

// The Pdf component encapsulates PDFJS to enable easy drawing of PDFs.
// The component will speed up drawing by only drawing pages when
// they become visible.
export class Pdf extends React.PureComponent {
  constructor(props) {
    super(props);
    // We use two variables to maintain the state of drawing.
    // isDrawing below is outside of the state variable.
    // isDrawing[pageNumber] is true when a page is currently
    // being drawn by PDFJS. It is set to false when drawing
    // is either successful or aborts.
    // isDrawn is in the state variable, since an update to
    // isDrawn should trigger a render update since we need to
    // draw comments after a page is drawn. Once a page is
    // successfully drawn we set isDrawn[pageNumber] to be the
    // filename of the drawn PDF. This way, if PDFs are changed
    // we know which pages are stale.
    this.state = {
      numPages: {},
      pdfDocument: {},
      scrollTop: 0,
      scrollWindowCenter: {
        x: 0,
        y: 0
      }
    };

    this.scrollLocation = {
      page: null,
      locationOnPage: 0
    };

    this.currentPage = 0;
    this.isGettingPdf = {};
    this.loadingTasks = {};
    this.shouldDraw = {};

    this.initializePredrawing();
    this.initializeRefs();
  }

  initializeRefs = () => {
    this.pageElements = {};
    this.scrollWindow = null;
  }

  initializePredrawing = () => {
    this.predrawnPdfs = {};
    this.isPrerdrawing = false;
  }

  scrollEvent = () => {
    this.setState({
      scrollTop: this.scrollWindow.scrollTop
    });

    // Now that the user is scrolling we reset the scroll location
    // so that we do not keep scrolling the user back.
    this.scrollLocation = {
      page: null,
      locationOnPage: 0
    };

    this.performFunctionOnEachPage((boundingRect, index) => {
      // You are on this page, if the top of the page is above the middle
      // and the bottom of the page is below the middle
      // jumpToPageNumber check is added to not update the page number when the
      // jump to page scroll is activated.
      if (!this.props.jumpToPageNumber && boundingRect.top < this.scrollWindow.clientHeight / 2 &&
          boundingRect.bottom > this.scrollWindow.clientHeight / 2) {
        this.onPageChange(index + 1);
      }
    });

    if (this.props.scrollToComment) {
      this.props.onScrollToComment(null);
    }

    if (this.props.jumpToPageNumber) {
      this.props.resetJumpToPage();
    }
  }

  performFunctionOnEachPage = (func) => {
    _.forEach(this.pageElements[this.props.file], (ele, index) => {
      if (ele.pageContainer) {
        const boundingRect = ele.pageContainer.getBoundingClientRect();

        func(boundingRect, Number(index));
      }
    });
  }

  // This method sets up the PDF. It sends a web request for the file
  // and when it receives it, starts to draw it.
  setUpPdf = (file) => {
    this.latestFile = file;

    return new Promise((resolve) => {
      this.getDocument(this.latestFile).then((pdfDocument) => {

        // Don't continue setting up the pdf if it's already been set up.
        if (!pdfDocument || pdfDocument === this.state.pdfDocument[this.latestFile]) {
          this.onPageChange(1);
          this.props.setPdfReadyToShow(this.props.documentId);

          return resolve();
        }

        this.setState({
          numPages: {
            ...this.state.numPages,
            [file]: pdfDocument.pdfInfo.numPages
          },
          pdfDocument: {
            ...this.state.pdfDocument,
            [file]: pdfDocument
          }
        }, () => {
          // If the user moves between pages quickly we want to make sure that we just
          // set up the most recent file, so we call this function recursively.
          this.setUpPdf(this.latestFile).then(() => {
            resolve();
          });
        });
      });
    });
  }

  setUpPdfObjects = (file, pdfDocument) => {
    if (!this.pageElements[file]) {
      this.pageElements[file] = {};
    }

    this.setState({
      numPages: {
        ...this.state.numPages,
        [file]: pdfDocument.pdfInfo.numPages
      }
    });
  }

  // This method is a wrapper around PDFJS's getDocument function. We wrap that function
  // so that we can call this whenever we need a reference to the document at the location
  // specified by `file`. This method will only make the request to the server once. Afterwards
  // it will return a cached version of it.
  getDocument = (file) => {
    const pdfsToKeep = [...this.props.prefetchFiles, this.props.file];

    if (!pdfsToKeep.includes(file)) {
      return Promise.resolve(null);
    }

    if (_.get(this.predrawnPdfs, [file, 'pdfDocument'])) {
      // If the document has already been retrieved, just return it.
      return Promise.resolve(this.predrawnPdfs[file].pdfDocument);
    } else if (this.isGettingPdf[file]) {
      // If the document is currently being retrieved we wait until it is, then return it.
      return new Promise((resolve) => {
        return setTimeout(() => {
          this.getDocument(file).then((pdfDocument) => {
            resolve(pdfDocument);
          });
        }, TIMEOUT_FOR_GET_DOCUMENT);
      });
    }

    // If the document has not been retrieved yet, we make a request to the server and
    // set isGettingPdf true so that we don't try to request it again, while the first
    // request is finishing.
    this.isGettingPdf[file] = true;
    this.loadingTasks[file] = PDFJS.getDocument({
      url: file,
      withCredentials: true
    });

    return this.loadingTasks[file].then((pdfDocument) => {
      this.loadingTasks[file] = null;
      this.isGettingPdf[file] = false;

      if ([...this.props.prefetchFiles, this.props.file].includes(file)) {
        // There is a chance another async call has resolved in the time that
        // getDocument took to run. If so, again just use the cached version.
        if (_.get(this.predrawnPdfs, [file, 'pdfDocument'])) {
          pdfDocument.destroy();

          return this.predrawnPdfs[file].pdfDocument;
        }
        this.predrawnPdfs[file] = {
          pdfDocument
        };
        this.setUpPdfObjects(file, pdfDocument);

        return pdfDocument;
      }
      pdfDocument.destroy();

      return null;
    }).
    catch(() => {
      this.isGettingPdf[file] = false;

      return null;
    });
  }

  scrollToPageLocation = (pageIndex, yPosition = 0) => {
    if (this.pageElements[this.props.file]) {
      const boundingBox = this.scrollWindow.getBoundingClientRect();
      const height = (boundingBox.bottom - boundingBox.top);
      const halfHeight = height / 2;

      this.scrollWindow.scrollTop =
        this.pageElements[this.props.file][pageIndex].pageContainer.getBoundingClientRect().top +
        yPosition + this.scrollWindow.scrollTop - halfHeight;

      return true;
    }

    return false;
  }

  onPageChange = (currentPage) => {
    const unscaledHeight = (_.get(this.pageElements,
      [this.props.file, currentPage - 1, 'pageContainer', 'offsetHeight']) / this.props.scale);

    this.currentPage = currentPage;
    this.props.onPageChange(
      currentPage,
      this.state.numPages[this.props.file],
      this.scrollWindow.offsetHeight / unscaledHeight);
  }

  handleAltC = () => {
    this.props.startPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);

    const scrollWindowBoundingRect = this.scrollWindow.getBoundingClientRect();
    const firstPageWithRoomForIconIndex = pageIndexOfPageNumber(this.currentPage);

    const iconPageBoundingBox =
      this.pageElements[this.props.file][firstPageWithRoomForIconIndex].pageContainer.getBoundingClientRect();

    const pageCoords = getInitialAnnotationIconPageCoords(
      iconPageBoundingBox,
      scrollWindowBoundingRect,
      this.props.scale
    );

    this.props.showPlaceAnnotationIcon(firstPageWithRoomForIconIndex, pageCoords);
  }

  handleAltEnter = () => {
    this.props.placeAnnotation(
      pageNumberOfPageIndex(this.props.placingAnnotationIconPageCoords.pageIndex),
      {
        xPosition: this.props.placingAnnotationIconPageCoords.x,
        yPosition: this.props.placingAnnotationIconPageCoords.y
      },
      this.props.documentId
    );
  }

  keyListener = (event) => {
    if (isUserEditingText()) {
      return;
    }

    if (event.altKey) {
      if (event.code === 'KeyC') {
        this.handleAltC();
      }

      if (event.code === 'Enter') {
        this.handleAltEnter();
      }
    }

    if (event.code === 'Escape' && this.props.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);
    }
  }

  updateScrollWindowCenter = () => {
    const rect = scrollWindow.getBoundingClientRect();

    this.setState({
      scrollWindowCenter: {
        x: rect.left + (rect.width / 2),
        y: rect.top + (rect.height / 2)
      }
    });
  }

  componentDidMount() {
    PDFJS.workerSrc = this.props.pdfWorker;
    window.addEventListener('keydown', this.keyListener);
    window.addEventListener('resize', this.updateScrollWindowCenter);

    this.setUpPdf(this.props.file);

    // focus the scroll window when the component initially loads.
    this.scrollWindow.focus();
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateScrollWindowCenter);
    window.removeEventListener('keydown', this.keyListener);
  }

  cleanUpPdf = (pdf, file) => {
    if (pdf.pdfDocument) {
      pdf.pdfDocument.destroy();
    }

    this.setState({
      pdfDocument: {
        ...this.state.pdfDocument,
        [file]: null
      }
    });
  }

  componentWillReceiveProps(nextProps) {
    // In general I think this is a good lint rule. However,
    // I think the below statements are clearer
    // with negative conditions.
    /* eslint-disable no-negated-condition */
    if (nextProps.file !== this.props.file) {
      this.scrollWindow.scrollTop = 0;
      this.setUpPdf(nextProps.file);

      // focus the scroll window when the document changes.
      this.scrollWindow.focus();
    } else if (nextProps.scale !== this.props.scale) {
      // Set the scroll location based on the current page and where you
      // are on that page scaled by the zoom factor.
      const zoomFactor = nextProps.scale / this.props.scale;
      const nonZoomedLocation = (this.scrollWindow.scrollTop -
        this.pageElements[this.props.file][this.currentPage - 1].pageContainer.offsetTop);

      this.scrollLocation = {
        page: this.currentPage,
        locationOnPage: nonZoomedLocation * zoomFactor
      };
    }

    if (nextProps.prefetchFiles !== this.props.prefetchFiles) {
      const pdfsToKeep = [...nextProps.prefetchFiles, nextProps.file];

      Object.keys(this.predrawnPdfs).forEach((file) => {
        if (!pdfsToKeep.includes(file)) {
          this.cleanUpPdf(this.predrawnPdfs[file], file);
        }
      });

      Object.keys(this.loadingTasks).forEach((file) => {
        if (!pdfsToKeep.includes(file) && this.loadingTasks[file]) {
          this.loadingTasks[file].destroy();
          delete this.loadingTasks[file];
        }
      });

      this.predrawnPdfs = _.pick(this.predrawnPdfs, pdfsToKeep);
    }
    /* eslint-enable no-negated-condition */
  }

  scrollToPage(pageNumber) {
    this.scrollWindow.scrollTop =
      this.pageElements[this.props.file][pageNumber - 1].pageContainer.getBoundingClientRect().top +
      this.scrollWindow.scrollTop - COVER_SCROLL_HEIGHT;
  }

  // eslint-disable-next-line max-statements
  componentDidUpdate() {
    // Wait until the page dimensions have been calculated, then it is
    // safe to jump to the pages since their positioning won't change.
    if (this.props.numberPagesSized === this.state.numPages[this.props.file] &&
      _.size(this.pageElements[this.props.file]) === this.state.numPages[this.props.file]) {
      if (this.props.jumpToPageNumber) {
        this.scrollToPage(this.props.jumpToPageNumber);
        this.onPageChange(this.props.jumpToPageNumber);
      }
      if (this.props.scrollToComment) {
        this.scrollToPageLocation(pageIndexOfPageNumber(this.props.scrollToComment.page),
          this.props.scrollToComment.y);
      }
    }

    if (this.scrollLocation.page) {
      this.scrollWindow.scrollTop = this.scrollLocation.locationOnPage +
        this.pageElements[this.props.file][this.scrollLocation.page - 1].pageContainer.offsetTop;
    }
  }

  getScrollWindowRef = (scrollWindow) => {
    this.scrollWindow = scrollWindow;
    this.updateScrollWindowCenter();
  }

  getPageContainerRef = (index, file, elem) => {
    if (elem) {
      _.set(this.pageElements[file], [index, 'pageContainer'], elem);
    } else {
      delete this.pageElements[file][index];
    }
  }

  // eslint-disable-next-line max-statements
  render() {
    const pages = _.map(this.state.numPages, (numPages, file) => _.range(numPages).map((page, pageIndex) => {
      if (this.state.pdfDocument[file]) {
        return <PdfPage
            scrollTop={this.scrollWindow.scrollTop}
            scrollWindowCenter={this.state.scrollWindowCenter}
            documentId={this.props.documentId}
            key={`${file}-${pageIndex + 1}`}
            file={file}
            pageIndex={pageIndex}
            isVisible={this.props.file === file}
            scale={this.props.scale}
            getPageContainerRef={this.getPageContainerRef}
            pdfDocument={this.state.pdfDocument[file]}
          />;
      }

      return null;
    }));

    return <div
      id="scrollWindow"
      tabIndex="0"
      className="cf-pdf-scroll-view"
      onScroll={this.scrollEvent}
      ref={this.getScrollWindowRef}>
        <div
          id={this.props.file}
          className={'cf-pdf-page pdfViewer singlePageView'}>
          {pages}
        </div>
      </div>;
  }
}

const mapStateToProps = (state, props) => ({
  ...state.readerReducer.ui.pdf,
  numberPagesSized: Object.keys(state.readerReducer.pages).filter((pageName) => pageName.includes(props.file)).length,
  ..._.pick(state.readerReducer, 'placingAnnotationIconPageCoords')
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
    startPlacingAnnotation,
    stopPlacingAnnotation,
    showPlaceAnnotationIcon,
    onScrollToComment,
    setPdfReadyToShow
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(Pdf);


Pdf.defaultProps = {
  onPageChange: _.noop,
  prefetchFiles: [],
  scale: 1
};

Pdf.propTypes = {
  selectedAnnotationId: PropTypes.number,
  documentId: PropTypes.number.isRequired,
  file: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  scale: PropTypes.number,
  onPageChange: PropTypes.func,
  scrollToComment: PropTypes.shape({
    id: PropTypes.number,
    page: PropTypes.number,
    y: PropTypes.number
  }),
  onIconMoved: PropTypes.func,
  setPdfReadyToShow: PropTypes.func,
  prefetchFiles: PropTypes.arrayOf(PropTypes.string)
};
