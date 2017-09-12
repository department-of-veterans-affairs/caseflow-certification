import React, { PureComponent } from 'react';
import TextareaField from '../../components/TextareaField';
import Table from '../../components/Table';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import HearingWorksheetSingleIssue from './HearingWorksheetPreImpressions';

import {
  onDescriptionChange,
  onToggleReopen,
  onToggleAllow,
  onToggleDeny,
  onToggleRemand,
  onToggleDismiss,
  onToggleVHA
       } from '../actions/Issue';

class HearingWorksheetIssues extends PureComponent {

  getKeyForRow = (index) => {
    return index;
  }

  onDescriptionChange = (description, id) => this.props.onDescriptionChange(id, description)


  render() {
    let {
     worksheetStreamsIssues
    } = this.props;

    const columns = [
      {
        header: '',
        valueName: 'counter'
      },
      {
        header: 'Program',
        align: 'left',
        valueName: 'program'
      },
      {
        header: 'Issue',
        align: 'left',
        valueName: 'issue'
      },
      {
        header: 'Levels 1-3',
        align: 'left',
        valueName: 'levels'
      },
      {
        header: 'Description',
        align: 'left',
        valueName: 'description'
      },
      {
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'actions'
      }
    ];


    // Maps over all issues inside stream
    const rowObjects = Object.keys(worksheetStreamsIssues).map((issue) => {


      let issueRow = worksheetStreamsIssues[issue];


      return {
        counter: <b>1.</b>,
        program: issueRow.program,
        levels: issueRow.levels,
        description: <div>
          <h4 className="cf-hearings-worksheet-desc-label">Description</h4>
          <TextareaField
            aria-label="Description"
            name="Description"
            id={issueRow.id}
            value={issueRow.description}
            onChange={this.onDescriptionChange.bind(issueRow.description, issueRow.id)}
            />
        </div>,
        actions: <div className="cf-hearings-worksheet-actions">
                  <HearingWorksheetSingleIssue
                    issue={worksheetStreamsIssues[issue]}
                    />
                  </div>
      };
    });

    return <Table
            className="cf-hearings-worksheet-issues"
            columns={columns}
            rowObjects={rowObjects}
            summary={'Worksheet Issues'}
            getKeyForRow={this.getKeyForRow}
          />;
  }
}
const mapStateToProps = (state) => ({
  HearingWorksheetIssues: state
});

// TODO to move the default value to the backend
const mapDispatchToProps = (dispatch) => bindActionCreators({
  onDescriptionChange,
  onToggleReopen,
  onToggleAllow,
  onToggleDeny,
  onToggleRemand,
  onToggleDismiss,
  onToggleVHA
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetIssues);

HearingWorksheetIssues.propTypes = {
  worksheetStreamsIssues: PropTypes.object.isRequired
};

