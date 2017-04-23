import React, { PropTypes } from 'react';
import SearchBar from '../SearchBar';
import Button from '../Button';

const DocumentListHeader = (props) => {

  let buttonText;
  let buttonAction;

  if (props.allCommentsExpanded) {
    buttonText = 'Collapse all';
    buttonAction = props.collapseAllPdfCommentList;
  } else {
    buttonText = 'Expand all';
    buttonAction = props.expandAllPdfCommentList;
  }

  return <div className="usa-grid-full document-list-header">
    <div className="usa-width-one-third">
      <SearchBar
        id="searchBar"
        onChange={props.onFilter}
        value={props.filterBy}
      />
    </div>
    <div className="usa-width-one-third num-of-documents">
      {props.numberOfDocuments} Documents
    </div>
    <div className="usa-width-one-third">
      <span className="cf-right-side">
        <Button
          id="btn-default"
          name={buttonText}
          onClick={ () => buttonAction() }
        />
      </span>
    </div>
  </div>;
};

DocumentListHeader.propTypes = {
  filterBy: PropTypes.string.isRequired,
  onFilter: PropTypes.func.isRequired,
  numberOfDocuments: PropTypes.number.isRequired
};

export default DocumentListHeader;
