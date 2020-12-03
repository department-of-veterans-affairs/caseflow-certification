// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

// Internal Dependencies
import { Comments } from 'components/reader/DocumentViewer/Comments';
import { pageNumber } from 'utils/reader';
import { markStyles, pdfPageStyles } from 'styles/reader/Document/Pdf';
import { commentIcon } from 'app/components/RenderFunctions';
import { showPage } from 'store/reader/documentViewer';

/**
 * PDF Page Component
 * @param {Object} props -- Contains the PDF Page props and functions to manipulate the rotation/scale/dimensions
 */
export const Page = ({
  addingComment,
  scale,
  pageRef,
  canvasRef,
  currentDocument,
  rotation,
  style,
  numColumns,
  rowIndex,
  columnIndex,
  dropComment,
  movingComment,
  moveComment,
  match,
  ...props
}) => {
  // Calculate the Page Index
  const pageIndex = (numColumns * rowIndex) + columnIndex;

  useEffect(() => {
    if (currentDocument?.id && props.isVisible) {
      showPage({
        pageIndex,
        scale,
        rotation: currentDocument.rotation,
        docId: match.params.docId,
        currentPage: pageIndex + 1,
      });

    }
  }, [currentDocument?.id, scale, currentDocument?.rotation]);

  return pageIndex >= currentDocument.numPages ? (
    <div key={(numColumns * rowIndex) + columnIndex} style={style} />
  ) : (
    <div key={pageIndex} style={style} >
      <div
        id={`pageContainer${pageNumber(pageIndex)}`}
        className={classNames({
          page: true,
          'cf-pdf-pdfjs-container': true,
          'cf-pdf-placing-comment': addingComment
        })}
        ref={pageRef}
        {...markStyles}
      >
        <div id={`rotationDiv${pageNumber(pageIndex)}`} style={pdfPageStyles(rotation, style.height, style.width)}>
          <canvas id={`pdf-canvas-${currentDocument.id}-${pageIndex}`} ref={canvasRef} className="canvasWrapper" />
          {addingComment && <div id="canvas-cursor" style={{ position: 'absolute' }}>{commentIcon()}</div>}
          <div className="cf-pdf-annotationLayer">
            <Comments
              {...props}
              handleDrop={(event) => moveComment(event, pageIndex)}
              dropComment={dropComment}
              movingComment={movingComment}
              moveMouse={(event) => props.moveMouse(event, pageIndex)}
              currentDocument={currentDocument}
              documentId={currentDocument.id}
              pageIndex={pageIndex}
              scale={scale}
              dimensions={{ width: style.width, height: style.height }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

Page.propTypes = {
  pageIndex: PropTypes.number,
  addingComment: PropTypes.bool,
  isVisible: PropTypes.bool,
  dropComment: PropTypes.func,
  movingComment: PropTypes.number,
  moveComment: PropTypes.func,
  scale: PropTypes.number,
  pageRef: PropTypes.element,
  canvasRef: PropTypes.element,
  currentDocument: PropTypes.object,
  rotation: PropTypes.number,
  style: PropTypes.object,
  match: PropTypes.object,
  numPages: PropTypes.number,
  numColumns: PropTypes.number,
  rowIndex: PropTypes.number,
  columnIndex: PropTypes.number,
  setPageNumber: PropTypes.func
};
