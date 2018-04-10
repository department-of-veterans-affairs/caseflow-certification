import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

import {
  CASE_DISPOSITION_DESCRIPTION_BY_ID,
  COLORS,
  ERROR_FIELD_REQUIRED
} from '../constants';

const dropdownStyling = (highlight, issueDisposition) => {
  if (highlight && !issueDisposition) {
    return css({
      borderLeft: `4px solid ${COLORS.ERROR}`,
      paddingLeft: '1rem',
      minHeight: '8rem'
    });
  }

  return css({
    minHeight: '12rem'
  });
};

class SelectIssueDispositionDropdown extends React.PureComponent {
  render = () => {
    const {
      highlight,
      issue
    } = this.props;

    return <div className="issue-disposition-dropdown"{...dropdownStyling(highlight, issue.disposition)}>
      <SearchableDropdown
        placeholder="Select Disposition"
        value={issue.disposition}
        hideLabel
        errorMessage={(highlight && !issue.disposition) ? ERROR_FIELD_REQUIRED : ''}
        options={Object.entries(CASE_DISPOSITION_DESCRIPTION_BY_ID).slice(0, 7).
          map((opt) => ({
            label: `${opt[0]} - ${opt[1]}`,
            value: opt[1]
          }))}
        onChange={({ value }) => this.props.updateIssue({
          disposition: value,
          readjudication: false
        })}
        name={`dispositions_dropdown_${issue.vacols_sequence_id}`} />
      {issue.disposition === 'Vacated' && <Checkbox
        name={`duplicate-vacated-issue-${issue.vacols_sequence_id}`}
        styling={css({
          marginBottom: 0,
          marginTop: '1rem'
        })}
        onChange={(readjudication) => this.props.updateIssue({ readjudication })}
        value={issue.readjudication}
        label="Automatically create vacated issue for readjudication." />}
    </div>;
  };
}

SelectIssueDispositionDropdown.propTypes = {
  issue: PropTypes.object.isRequired,
  vacolsId: PropTypes.string.isRequired,
  highlight: PropTypes.bool,
  updateIssue: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({
  highlight: state.ui.highlightFormItems
});

export default connect(mapStateToProps)(SelectIssueDispositionDropdown);
