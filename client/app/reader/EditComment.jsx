import React from 'react';
import PropTypes from 'prop-types';

import DateSelector from '../components/DateSelector';
import SaveCommentTextArea from '../components/SaveCommentTextArea';

// A rounded rectangle with a text box for adding
// or editing an existing comment.
export default class EditComment extends React.Component {

  constructor(props) {
    super(props);

    this.shouldAutosave = true;
  }

  handleAutoSave = () => {
    // only autosave when a comment exists
    if (this.shouldAutosave && this.props.comment.comment) {
      this.onSaveCommentEdit();
    }
  }

  keyListener = (event) => {
    if (event.altKey && event.key === 'Enter' && this.props.comment.comment && this.props.comment.comment.trim()) {
      this.onSaveCommentEdit();
      event.stopPropagation();
    }
  }

  componentDidMount = () => {
    let commentBox = document.getElementById(this.props.id);

    commentBox.focus();

    // ensure we autosave if we ever exit
    window.addEventListener('beforeunload', this.handleAutoSave);
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.handleAutoSave);
    this.handleAutoSave();
  }

  onChange = (event) => this.props.onChange(event.target.value, this.props.comment.uuid);

  onChangeDate = (relevantDate) => this.props.onChangeDate(relevantDate, this.props.comment.uuid);

  onCancelCommentEdit = () => {
    this.shouldAutosave = false;
    this.props.onCancelCommentEdit(this.props.comment.uuid);
  }

  onSaveCommentEdit = () => {
    this.shouldAutosave = false;
    this.props.onSaveCommentEdit(this.props.comment);
  }

  isStringEmpty = (str = '') => !str.trim();

  render() {
    return <div>
      <DateSelector
        name="Relevant Date"
        onChange={this.onChangeDate}
        value={this.props.comment.relevant_date}
        type="date"
        strongLabel
      />
      <SaveCommentTextArea
        onKeyDown={this.keyListener}
        hideLabel
        id={this.props.id}
        onChange={this.onChange}
        value={this.props.comment.comment}
        onCancelClick={this.onCancelCommentEdit}
        onSaveClick={this.onSaveCommentEdit}
        disabled={this.props.disableOnEmpty && this.isStringEmpty(this.props.comment.comment)}
      />
    </div>;
  }
}

EditComment.defaultProps = {
  id: 'commentEditBox'
};

EditComment.propTypes = {
  comment: PropTypes.object.isRequired,
  disableOnEmpty: PropTypes.bool,
  id: PropTypes.string,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func
};
