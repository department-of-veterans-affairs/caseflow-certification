import React, { PropTypes } from 'react';
import { formatDate } from '../util/DateUtil';
import Comment from '../components/Comment';
import SearchableDropdown from '../components/SearchableDropdown';
import EditComment from '../components/EditComment';
import _ from 'lodash';
import Alert from '../components/Alert';
import Button from '../components/Button';
import { connect } from 'react-redux';
import * as Constants from '../reader/constants';
import ApiUtil from '../util/ApiUtil';
import { categoryFieldNameOfCategoryName } from '../reader/utils';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import { plusIcon } from './RenderFunctions';
import classNames from 'classnames';

// PdfSidebar shows relevant document information and comments.
// It is intended to be used with the PdfUI component to
// show a PDF with its corresponding information.
export class PdfSidebar extends React.Component {
  generateOptionsFromTags = (tags) =>
    _.map(tags, (tag) => ({
      value: tag.text,
      label: tag.text,
      tagId: tag.id })
    );

  onChange = (values, deletedValue) => {
    if (_.size(deletedValue)) {
      const tagValue = _.first(deletedValue).label;
      const result = _.find(this.props.doc.tags, { text: tagValue });

      this.props.removeTag(this.props.doc, result.id);
    } else if (values && values.length) {
      this.props.addNewTag(this.props.doc, values);
    }
  }

  render() {
    let comments = [];

    const {
      doc,
      showTagErrorMsg
    } = this.props;

    comments = this.props.comments.map((comment, index) => {
      if (comment.uuid === this.props.editingComment) {
        return <EditComment
            id="editCommentBox"
            onCancelCommentEdit={this.props.onCancelCommentEdit}
            onSaveCommentEdit={this.props.onSaveCommentEdit}
            key={comment.comment}
          >
            {comment.comment}
          </EditComment>;
      }

      return <Comment
        id={`comment${index}`}
        selected={false}
        onDeleteComment={this.props.onDeleteComment}
        onEditComment={this.props.onEditComment}
        uuid={comment.uuid}
        selected={comment.selected}
        onClick={this.props.onJumpToComment(comment)}
        page={comment.page}
        key={comment.comment}>
          {comment.comment}
        </Comment>;
    });

    const sidebarClass = classNames(
      'cf-sidebar-wrapper',
      { 'hidden-sidebar': this.props.hidePdfSidebar });
    const categoryToggleStates = _.mapValues(
      Constants.documentCategories,
      (val, key) =>
        this.props.documents[this.props.doc.id][categoryFieldNameOfCategoryName(key)]
    );

    return <div className={sidebarClass}>
        <div className="cf-sidebar-header">
          <Button
            name="hide menu"
            classNames={['cf-pdf-button']}
            onClick={this.props.handleTogglePdfSidebar}>
            <strong>
              Hide menu <i className="fa fa-chevron-right" aria-hidden="true"></i>
            </strong>
          </Button>
        </div>
        <div className="cf-document-info-wrapper">
          <p className="cf-pdf-meta-title cf-pdf-cutoff">
            <b>Document Type: </b>
            <span title={this.props.doc.type}>
              {this.props.doc.type}
            </span>
          </p>
          <p className="cf-pdf-meta-title">
            <b>Receipt Date:</b> {formatDate(this.props.doc.receivedAt)}
          </p>
          <DocCategoryPicker
            handleCategoryToggle={
              _.partial(this.props.handleCategoryToggle, this.props.doc.id)
            }
            categoryToggleStates={categoryToggleStates} />
          <div className="cf-sidebar-heading cf-sidebar-heading-related-issues">
            Related Issues
          </div>
          {/* This error alert needs to be formatted according to #1573 */}
          {showTagErrorMsg &&
            <Alert type="error" title={''}
              message="Unable to save. Please try again." />}
          <SearchableDropdown
            name="tags"
            label="Click in the box to select, or add issue(s)"
            multi={true}
            creatable={true}
            options={this.generateOptionsFromTags(doc.tags)}
            placeholder=""
            value={this.generateOptionsFromTags(doc.tags)}
            onChange={this.onChange}
            selfManageValueState={true}
          />
          <div className="cf-sidebar-heading">
            Comments
            <span className="cf-right-side cf-add-comment-button">
              <Button
                name="AddComment"
                onClick={this.props.onAddComment}>
                <span>{ plusIcon() } &nbsp; Add a comment</span>
              </Button>
            </span>
          </div>
        </div>

        <div className="cf-comment-wrapper">
          <div className="cf-pdf-comment-list">
            {this.props.isAddingComment &&
              <EditComment
                id="addComment"
                onCancelCommentEdit={this.props.onCancelCommentAdd}
                onSaveCommentEdit={this.props.onSaveCommentAdd} />}
            {comments}
          </div>
        </div>
      </div>;
  }
}

PdfSidebar.propTypes = {
  onAddComment: PropTypes.func,
  doc: PropTypes.object,
  comments: React.PropTypes.arrayOf(React.PropTypes.shape({
    comment: React.PropTypes.string,
    uuid: React.PropTypes.number
  })),
  editingComment: React.PropTypes.number,
  isAddingComment: PropTypes.bool,
  onSaveCommentAdd: PropTypes.func,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func,
  onCancelCommentAdd: PropTypes.func,
  onDeleteComment: PropTypes.func,
  onJumpToComment: PropTypes.func,
  handleTogglePdfSidebar: PropTypes.func,
  hidePdfSidebar: PropTypes.bool
};

const mapPropsToState = (state) => ({
  documents: state.documents,
  hidePdfSidebar: state.ui.pdf.hidePdfSidebar
});
const mapDispatchToState = (dispatch) => ({
  handleCategoryToggle(docId, categoryName, toggleState) {
    const categoryKey = categoryFieldNameOfCategoryName(categoryName);

    ApiUtil.patch(
      `/document/${docId}`,
      { data: { [categoryKey]: toggleState } }
    ).catch((err) => {
      // eslint-disable-next-line no-console
      console.log('Saving document category failed', err);
    });

    dispatch({
      type: Constants.TOGGLE_DOCUMENT_CATEGORY,
      payload: {
        categoryName,
        toggleState,
        docId
      }
    });
  },
  handleTogglePdfSidebar() {
    dispatch({
      type: Constants.TOGGLE_PDF_SIDEBAR
    });
  }
});

export default connect(
  mapPropsToState, mapDispatchToState
)(PdfSidebar);
