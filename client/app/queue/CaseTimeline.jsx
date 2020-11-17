import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { caseTimelineTasksForAppeal } from './selectors';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';

export class CaseTimeline extends React.PureComponent {
  constructor() {
    super();
    this.state = { editNODChangeSuccessful: false };
  }

  render = () => {
    const {
      appeal,
      tasks,
    } = this.props;

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <TaskRows appeal={appeal}
            taskList={tasks}
            editNodDateEnabled={this.props.featureToggles?.editNodDate}
            timeline
          />
        </tbody>
      </table>
    </React.Fragment>;
  }
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object,
  tasks: PropTypes.array,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),
    featureToggles: state.ui.featureToggles
  };
};

export default connect(mapStateToProps)(CaseTimeline);
