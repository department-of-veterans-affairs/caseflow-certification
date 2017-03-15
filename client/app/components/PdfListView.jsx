import React, { PropTypes } from 'react';
import Table from '../components/Table';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import SearchBar from '../components/SearchBar';
import StringUtil from '../util/StringUtil';
import Button from '../components/Button';

export default class PdfListView extends React.Component {
  getDocumentColumns = () => {
    let className;

    if (this.props.sortDirection === 'ascending') {
      className = "fa-caret-down";
    } else {
      className = "fa-caret-up";
    }

    let sortIcon = <i className={`fa ${className}`} aria-hidden="true"></i>;

    // We have blank headers for the comment indicator and label indicator columns
    return [
      {
        valueFunction: (doc) => {
          return <span>
            {doc.label && <i
            className={`fa fa-bookmark cf-pdf-bookmark-` +
              `${StringUtil.camelCaseToDashCase(doc.label)}`}
            aria-hidden="true"></i> }
          </span>;
        }
      },
      {
        valueFunction: (doc) => {
          let numberOfComments = this.props.annotationStorage.
            getAnnotationByDocumentId(doc.id).length;

          return <span className="fa-stack fa-3x cf-pdf-comment-indicator">
            { numberOfComments > 0 &&
                <span>
                  <i className="fa fa-comment-o fa-stack-2x"></i>
                  <strong className="fa-stack-1x fa-stack-text">
                    {numberOfComments}
                  </strong>
                </span>
            }
          </span>;
        }
      },
      {
        header: <div onClick={this.props.changeSortState('date')}>
          Receipt Date {this.props.sortBy === 'date' ? sortIcon : ' '}
        </div>,
        valueFunction: (doc) => formatDate(doc.received_at)
      },
      {
        header: <div onClick={this.props.changeSortState('type')}>
          Document Type {this.props.sortBy === 'type' ? sortIcon : ' '}
        </div>,
        valueName: "type"
      },
      {
        header: <div onClick={this.props.changeSortState('filename')}>
          Filename {this.props.sortBy === 'filename' ? sortIcon : ' '}
        </div>,
        valueFunction: (doc, index) =>
          <a onClick={this.props.showPdf(index)}>{doc.filename}</a>
      }
    ];
  }

  render() {
    let commentSelectorClassNames = ['cf-pdf-button'];

    if (this.props.isCommentLabelSelected) {
      commentSelectorClassNames.push('cf-selected-label');
    } else {
      commentSelectorClassNames.push('cf-label');
    }

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <div className="usa-grid-full">
            <div className="usa-width-one-third">
              <SearchBar onChange={this.props.onFilter} value={this.props.filterBy} />
            </div>
            <div className="usa-width-one-third">
              <span>
                Show only:
                <DocumentLabels
                  onClick={this.props.selectLabel}
                  selectedLabels={this.props.selectedLabels} />
              </span>
              <span>
                <Button
                  name="comment-selector"
                  onClick={this.props.selectComments}
                  classNames={commentSelectorClassNames}>
                  <i className="fa fa-comment-o fa-lg"></i>
                </Button>
              </span>
            </div>
            <div className="usa-width-one-third">
              <span className="cf-right-side">
                Showing {`${this.props.documents.length} out of ` +
                `${this.props.numberOfDocuments}`} documents
              </span>
            </div>
          </div>
          <div>
            <Table
              columns={this.getDocumentColumns()}
              rowObjects={this.props.documents}
              summary="Document list"
            />
          </div>
        </div>
      </div>
    </div>;
  }
}

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  filterBy: PropTypes.string.isRequired,
  numberOfDocuments: PropTypes.number.isRequired,
  onFilter: PropTypes.func.isRequired
};
