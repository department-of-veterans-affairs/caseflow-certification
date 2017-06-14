import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants';
import ApiUtil from '../util/ApiUtil';
import { onReceiveAssignments, onInitialDataLoadingFail } from './actions';
import { Link } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import Table from '../components/Table';

class CaseSelect extends React.PureComponent {
  getAssignmentColumn = () => {
    return [
      {
        header: 'Veteran',
        valueName: 'veteran_name'
      },
      {
        header: 'Veteran ID',
        valueName: 'veteran_id'
      },
      {
        header: 'View Case File',
        valueFunction: (row) => {
          return <Link to={`/${row.vacols_id}/documents`}>View Case</Link>;
        }
      }
    ];
  }

  getKeyForRow = (index, row) => {
    return row.vacols_id;
  }

  render() {
    if (!this.props.assignments) {
      return <div></div>;
    }
    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Welcome to Reader!</h1>
          <p className="cf-lead-paragraph">
            Reader allows attorneys and judges to review
            and annotate Veteran claims folders.
            Learn more about Reader on our <a href="/reader/help">Help page</a>.
          </p>
          <h1>Work Assignments</h1>
          <Table
            columns={this.getAssignmentColumn}
            rowObjects={this.props.assignments.cases}
            summary="Work Assignments"
            getKeyForRow={this.getKeyForRow}
          />
        </div>
      </div>
    </div>;
  }

  componentDidMount() {
    ApiUtil.get('/reader/appeal').then((response) => {
      const returnedObject = JSON.parse(response.text);

      this.props.onReceiveAssignments(returnedObject);
    }, this.props.onInitialDataLoadingFail);
  }
}

const mapStateToProps = (state) => {
  return _.pick(state, 'assignments');
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onInitialDataLoadingFail,
    onReceiveAssignments
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelect);
