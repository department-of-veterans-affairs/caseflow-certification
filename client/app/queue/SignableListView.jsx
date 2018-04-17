import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import SignableTable from './SignableTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';

class SignableListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  render = () => {
    const reviewableTasks = {};
    let reviewableCount = 0;
    for (const k in this.props.tasks) {
      if (this.props.tasks[k].attributes.task_type === "Review") {
        reviewableCount++;
      }
    }
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <StatusMessage title="Tasks not found">
        Congratulations! You don't have any decisions to sign.
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 {...fullWidth}>Review {reviewableCount} Cases</h1>
        <SignableTable />
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

SignableListView.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue.loadedQueue, 'tasks', 'appeals'),
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(SignableListView);
