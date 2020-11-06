// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { toolbarStyles, pdfButtonStyle } from 'styles/reader/Document/Pdf';
import Button from 'app/components/Button';
import Link from 'app/components/Link';
import {
  LeftChevron,
  ExternalLink,
  FitToScreen,
  Rotate,
  SearchIcon,
  downloadIcon
} from 'app/components/RenderFunctions';
import DocumentCategoryIcons from 'app/reader/DocumentCategoryIcons';

// TODO: Move to constants in later part of the stack
const ZOOM_RATE = 0.3;

/**
 * Document Header displays the PDF navigation controls
 * @param {Object} props -- Contains details about the PDF navigation and sidebar
 */
export const DocumentHeader = ({
  showClaimsFolderNavigation,
  documentPathBase,
  doc,
  zoom,
  backToClaimsFolder,
  openDocument,
  fitToScreen,
  rotateDocument,
  download,
  toggleSearchBar,
  hidePdfSidebar,
  togglePdfSidebar
}) => (
  <div className="cf-pdf-header cf-pdf-toolbar">
    <span {...toolbarStyles.toolbar} {...toolbarStyles.toolbarLeft}>
      {showClaimsFolderNavigation && (
        <Link to={`${documentPathBase}`} name="backToClaimsFolder" button="matte" onClick={backToClaimsFolder}>
          <LeftChevron />
          &nbsp; Back
        </Link>
      )}
    </span>
    <span {...toolbarStyles.toolbar} {...toolbarStyles.toolbarCenter}>
      <span className="category-icons-and-doc-type">
        <span className="cf-pdf-doc-category-icons">
          <DocumentCategoryIcons doc={doc} />
        </span>
        <span className="cf-pdf-doc-type-button-container">
          <Link
            name="newTab"
            ariaLabel="open document in new tab"
            target="_blank"
            button="matte"
            onClick={openDocument}
            href={`/reader/appeal${documentPathBase}/${doc.id}`}
          >
            <h1 className="cf-pdf-vertically-center cf-non-stylized-header">
              <span title="Open in new tab">{doc.type}</span>
              <span className="cf-pdf-external-link-icon">
                <ExternalLink />
              </span>
            </h1>
          </Link>
        </span>
      </span>
    </span>
    <span {...toolbarStyles.toolbar} {...toolbarStyles.toolbarRight}>
      <span className="cf-pdf-button-text">Zoom:</span>
      <Button name="zoomOut" classNames={pdfButtonStyle} onClick={zoom(-ZOOM_RATE)} ariaLabel="zoom out" >
        <i className="fa fa-minus" aria-hidden="true" />
      </Button>
      <Button name="zoomIn" classNames={pdfButtonStyle} onClick={zoom(ZOOM_RATE)} ariaLabel="zoom in" >
        <i className="fa fa-plus" aria-hidden="true" />
      </Button>
      <Button name="fit" classNames={pdfButtonStyle} onClick={fitToScreen} ariaLabel="fit to screen" >
        <FitToScreen />
      </Button>
      <Button name="rotation" classNames={pdfButtonStyle} onClick={rotateDocument} ariaLabel="rotate document" >
        <Rotate />
      </Button>
      <span className="cf-pdf-spaced-buttons">|</span>
      <Button
        name="download"
        classNames={['cf-pdf-button cf-pdf-download-icon']}
        onClick={download}
        ariaLabel="download pdf"
      >
        {downloadIcon()}
      </Button>
      <Button
        name="search"
        classNames={['cf-pdf-button cf-pdf-search usa-search usa-search-small']}
        ariaLabel="search text"
        type="submit"
        onClick={toggleSearchBar}
      >
        <SearchIcon />
      </Button>
      {hidePdfSidebar && (
        <span {...toolbarStyles.openSidebarMenu}>
          <Button name="open sidebar menu" classNames={['cf-pdf-button']} onClick={togglePdfSidebar}>
            <strong>
              Open menu
            </strong>
          </Button>
        </span>
      )}
    </span>
  </div>
);

DocumentHeader.propTypes = {
  currentIndex: PropTypes.number,
  prevDocId: PropTypes.number,
  nextDocId: PropTypes.number,
  loadError: PropTypes.string,
  docsFiltered: PropTypes.bool,
  filteredDocIds: PropTypes.array,
  nextDoc: PropTypes.number,
  numPages: PropTypes.number,
  setPageNumber: PropTypes.func,
  handleKeyPress: PropTypes.func,
  pageNumber: PropTypes.number,
  showClaimsFolderNavigation: PropTypes.bool,
  documentPathBase: PropTypes.string,
  doc: PropTypes.object,
  zoom: PropTypes.func,
  backToClaimsFolder: PropTypes.func,
  openDocument: PropTypes.func,
  fitToScreen: PropTypes.func,
  rotateDocument: PropTypes.func,
  download: PropTypes.func,
  toggleSearchBar: PropTypes.func,
  hidePdfSidebar: PropTypes.bool,
  togglePdfSidebar: PropTypes.func,
};
