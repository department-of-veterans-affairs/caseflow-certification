// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import DateSelector from 'app/components/DateSelector';
import SaveableTextArea from 'app/components/SaveableTextArea';

/**
 * Edit Comment Component is a rounded rectangle with a text box for adding or editing an existing comment
 * @param {Object} props -- Contains details about the comment and functions to modify
 */
export const EditComment = ({
  savingComment,
  disableOnEmpty,
  comment,
  saveComment,
  resetEdit,
  changeDate,
  onChange,
  keyListener,
  nodeId
}) => (
  <div>
    <DateSelector
      name="Relevant Date"
      onChange={changeDate}
      value={comment.pendingDate || comment.relevant_date}
      type="date"
      strongLabel
    />
    <SaveableTextArea
      name="Edit comment"
      hideLabel
      onKeyDown={keyListener}
      id={nodeId}
      onChange={onChange}
      value={comment.pendingComment || comment.comment}
      onCancelClick={resetEdit}
      onSaveClick={saveComment}
      disabled={savingComment || (disableOnEmpty && !comment.pendingComment.trim())}
    />
  </div>
);

EditComment.defaultProps = {
  nodeId: 'commentEditBox'
};

EditComment.propTypes = {
  savingComment: PropTypes.bool,
  comment: PropTypes.object.isRequired,
  disableOnEmpty: PropTypes.bool,
  nodeId: PropTypes.string,
  saveComment: PropTypes.func,
  resetEdit: PropTypes.func,
  changeDate: PropTypes.func,
  onChange: PropTypes.func,
  keyListener: PropTypes.func,
};