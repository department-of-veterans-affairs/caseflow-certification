import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';
import Comment from '../components/Comment';
import Button from '../components/Button';
import { linkToSingleDocumentView } from '../components/PdfUI';
import DocumentCategoryIcons from '../components/DocumentCategoryIcons';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import * as Constants from './constants';
import DropdownFilter from './DropdownFilter';
import _ from 'lodash';
import DocCategoryPicker from './DocCategoryPicker';
import {
  SelectedFilterIcon, UnselectedFilterIcon, rightTriangle
} from '../components/RenderFunctions';

const NUMBER_OF_COLUMNS = 6;

const FilterIcon = ({
  handleActivate, label, getRef, selected, idPrefix
}) => {
  const handleKeyDown = (event) => {
    if (event.key === ' ' || event.key === 'Enter') {
      handleActivate(event);
      event.preventDefault();
    }
  };

  const className = 'table-icon';

  const props = {
    role: 'button',
    getRef,
    'aria-label': label,
    className,
    tabIndex: '0',
    onKeyDown: handleKeyDown,
    onClick: handleActivate
  };

  if (selected) {
    return <SelectedFilterIcon {...props} idPrefix={idPrefix} />;
  }

  return <UnselectedFilterIcon {...props} />;
};

FilterIcon.propTypes = {
  label: PropTypes.string.isRequired,
  iconName: PropTypes.string,
  handleActivate: PropTypes.func,
  getRef: PropTypes.func,
  idPrefix: PropTypes.string.isRequired,
  className: PropTypes.string
};

export class PdfListView extends React.Component {
  constructor() {
    super();
    this.state = {
      filterPositions: {}
    };
  }

  componentDidMount() {
    window.addEventListener('resize', this.setCategoryFilterIconPosition);
    this.setCategoryFilterIconPosition();
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.setCategoryFilterIconPosition);
  }

  setCategoryFilterIconPosition = () => {
    this.setState({
      filterPositions: {
        category: _.merge({}, this.categoryFilterIcon.getBoundingClientRect())
      }
    });
  }

  toggleComments = (id) => () => {
    this.props.handleToggleCommentOpened(id);
  }

  getDocumentColumns = () => {
    const className = this.props.sort.sortAscending ? 'fa-caret-down' : 'fa-caret-up';

    let sortIcon = <i className={`fa fa-1 ${className} table-icon`}
      aria-hidden="true"></i>;
    let notsortedIcon = <i className="fa fa-1 fa-arrows-v table-icon"
      aria-hidden="true"></i>;

    let boldUnreadContent = (content, doc) => {
      if (!doc.opened_by_current_user) {
        return <b>{content}</b>;
      }

      return content;
    };

    const toggleCategoryDropdownFilterVisiblity = () =>
      this.props.toggleDropdownFilterVisiblity('category');

    const clearFilters = () => {
      _(Constants.documentCategories).keys().
        forEach((categoryName) => this.props.setCategoryFilter(categoryName, false));
    };

    const anyCategoryFiltersAreSet = Boolean(_.some(this.props.pdfList.filters.category));

    // We have blank headers for the comment indicator and label indicator columns.
    // We use onMouseUp instead of onClick for filename event handler since OnMouseUp
    // is triggered when a middle mouse button is clicked while onClick isn't.
    return (row) => {
      if (row && row.isComment) {
        return [{
          valueFunction: (doc) => {
            const comments = this.props.annotationStorage.
              getAnnotationByDocumentId(doc.id);
            const commentNodes = comments.map((comment, commentIndex) => {
              return <Comment
                key={comment.uuid}
                id={`comment${doc.id}-${commentIndex}`}
                selected={false}
                page={comment.page}
                onJumpToComment={this.props.onJumpToComment(comment)}
                uuid={comment.uuid}
                horizontalLayout={true}>
                  {comment.comment}
                </Comment>;
            });

            return <ul className="cf-no-styling-list" aria-label="Document comments">
              {commentNodes}
            </ul>;
          },
          span: _.constant(NUMBER_OF_COLUMNS)
        }];
      }

      const isCategoryDropdownFilterOpen =
        _.get(this.props.pdfList, ['dropdowns', 'category']);

      return [
        {
          valueFunction: (doc) => {
            if (doc.id === this.props.pdfList.lastReadDocId) {
              return <span aria-label="Most recently read document indicator">
                  {rightTriangle()}
                </span>;
            }
          }
        },
        {
          header: <div
            id="categories-header"
            className="document-list-header-categories">
            Categories <FilterIcon
              label="Filter by category"
              idPrefix="category"
              getRef={(categoryFilterIcon) => {
                this.categoryFilterIcon = categoryFilterIcon;
              }}
              selected={isCategoryDropdownFilterOpen || anyCategoryFiltersAreSet}
              handleActivate={toggleCategoryDropdownFilterVisiblity} />

            {isCategoryDropdownFilterOpen &&
              <DropdownFilter baseCoordinates={this.state.filterPositions.category}
                clearFilters={clearFilters}
                isClearEnabled={anyCategoryFiltersAreSet}
                handleClose={toggleCategoryDropdownFilterVisiblity}>
                <DocCategoryPicker
                  categoryToggleStates={this.props.pdfList.filters.category}
                  handleCategoryToggle={this.props.setCategoryFilter} />
              </DropdownFilter>
            }

          </div>,
          valueFunction: (doc) => <DocumentCategoryIcons docId={doc.id} />
        },
        {
          header: <div
            id="receipt-date-header"
            className="document-list-header-recepit-date"
            onClick={() => this.props.changeSortState('date')}>
            Receipt Date {this.props.sort.sortBy === 'date' ? sortIcon : notsortedIcon}
          </div>,
          valueFunction: (doc) =>
            <span className="document-list-receipt-date">
              {formatDate(doc.receivedAt)}
            </span>
        },
        {
          header: <div id="type-header" onClick={() => this.props.changeSortState('type')}>
            Document Type {this.props.sort.sortBy === 'type' ? sortIcon : notsortedIcon}
          </div>,
          valueFunction: (doc) => boldUnreadContent(
            <a
              href={linkToSingleDocumentView(doc)}
              onMouseUp={this.props.showPdf(doc.id)}>
              {doc.type}
            </a>, doc)
        },
        {
          header: <div id="issue-tags-header"
            className="document-list-header-issue-tags">
            Issue Tags <FilterIcon label="Filter by issue" idPrefix="issue" />
          </div>,
          valueFunction: () => {
            return <div className="document-list-issue-tags">
            </div>;
          }
        },
        {
          align: 'center',
          header: <div
            id="comments-header"
            className="document-list-header-comments"
          >
            Comments
          </div>,
          valueFunction: (doc) => {
            const numberOfComments = this.props.annotationStorage.
              getAnnotationByDocumentId(doc.id).length;
            const icon = `fa fa-3 ${this.props.reduxDocuments[doc.id].listComments ?
              'fa-angle-up' : 'fa-angle-down'}`;
            const name = `expand ${numberOfComments} comments`;

            return <span className="document-list-comments-indicator">
              {numberOfComments > 0 &&
                <span>
                  <Button
                    classNames={['cf-btn-link']}
                    href="#"
                    ariaLabel={name}
                    name={name}
                    id={`expand-${doc.id}-comments-button`}
                    onClick={this.toggleComments(doc.id)}>{numberOfComments}
                    <i className={`document-list-comments-indicator-icon ${icon}`}/>
                  </Button>
                </span>
              }
            </span>;
          }
        }
      ];
    };
  }

  render() {
    let commentSelectorClassNames = ['cf-pdf-button'];

    if (this.props.isCommentLabelSelected) {
      commentSelectorClassNames.push('cf-selected-label');
    } else {
      commentSelectorClassNames.push('cf-label');
    }

    let rowObjects = this.props.documents.reduce((acc, row) => {
      acc.push(row);
      if (this.props.reduxDocuments[row.id].listComments) {
        acc.push({
          ...row,
          isComment: true
        });
      }

      return acc;
    }, []);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <DocumentListHeader
            documents={this.props.documents}
            onFilter={this.props.onFilter}
            filterBy={this.props.filterBy}
            numberOfDocuments={this.props.numberOfDocuments}
          />
          <div>
            <Table
              columns={this.getDocumentColumns()}
              rowObjects={rowObjects}
              summary="Document list"
              headerClassName="cf-document-list-header-row"
              rowsPerRowObject={2}
            />
          </div>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  ..._.pick(state.ui, ['pdfList', 'sort']),

  // Should be merged with documents when we finish integrating redux
  reduxDocuments: state.documents
});

const mapDispatchToProps = (dispatch) => ({
  changeSortState(sortBy) {
    dispatch({
      type: Constants.SET_SORT,
      payload: {
        sortBy
      }
    });
  },
  toggleDropdownFilterVisiblity(filterName) {
    dispatch({
      type: Constants.TOGGLE_FILTER_DROPDOWN,
      payload: {
        filterName
      }
    });
  },
  setCategoryFilter(categoryName, checked) {
    dispatch({
      type: Constants.SET_CATEGORY_FILTER,
      payload: {
        categoryName,
        checked
      }
    });
  },
  handleToggleCommentOpened(docId) {
    dispatch({
      type: Constants.TOGGLE_COMMENT_LIST,
      payload: {
        docId
      }
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  filterBy: PropTypes.string.isRequired,
  numberOfDocuments: PropTypes.number.isRequired,
  onFilter: PropTypes.func.isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  reduxDocuments: PropTypes.object.isRequired,
  handleToggleCommentOpened: PropTypes.func.isRequired,
  pdfList: PropTypes.shape({
    lastReadDocId: PropTypes.number
  })
};
