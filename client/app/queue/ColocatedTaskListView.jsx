// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AmaTaskTable from './components/AmaTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  amaTasksAssignedTo
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import TabWindow from '../components/TabWindow';
import type { AmaTask } from './types/models';
import type { State } from './types/state';

type Params = {|
  userId: number
|};

type Props = Params & {|
  // Action creators
  clearCaseSelectSearch: typeof clearCaseSelectSearch
|};

const NewTasksTab = connect(
  (state: State, ownProps) => ({ tasks: amaTasksAssignedTo(state, { userId: ownProps.userId }) }))(
  (props: { tasks: Array<AmaTask> }) => {
    return <div>
      <p>These are new administrative actions that have been assigned to you.</p>
      <AmaTaskTable tasks={props.tasks} />
    </div>;
  });

class ColocatedTaskListView extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  pageNew = () => {
    return <NewTasksTab userId={this.props.userId} />;
  }

  render = () => {
    const tabs = [{
      label: 'New',
      page: this.pageNew()
    }];

    return <AppSegment filledBackground>
      <TabWindow name="tasks-tabwindow" tabs={tabs} />
    </AppSegment>;
  };
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch
}, dispatch);

export default (connect(null, mapDispatchToProps)(ColocatedTaskListView): React.ComponentType<Params>);
