import React from 'react';
import { connect } from 'react-redux';
import type { State } from './types/state';
import { allCompleteTasksForAppeal, allTasksForTimeline } from './selectors';
import COPY from '../../COPY.json';
import TaskRows from './components/TaskRows';

type Params = {|
  appealId: string
|};

class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal
    } = this.props;

    console.log('--Timeline--');
    console.log(this.props.completedTasks);
    console.log(this.props.timelineTasks);

    // Need to check on on_hold
    // gray dot spacing
    // double view-hide task instructions appearing

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table>
        <tbody>
          { <TaskRows appeal={appeal} taskList={this.props.timelineTasks} timeline /> }
        </tbody>
      </table>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {

  return {
    completedTasks: allCompleteTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),
    timelineTasks: allTasksForTimeline(state, { appealId: ownProps.appeal.externalId })
  };
};

export default connect(mapStateToProps)(CaseTimeline);
