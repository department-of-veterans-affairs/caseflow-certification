// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AmaTaskTable from './components/AmaTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  amaTasksNewByAssigneeCssIdSelector,
  amaTasksOnHoldByAssigneeCssIdSelector
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import TabWindow from '../components/TabWindow';
import COPY from '../../COPY.json';

import type { AmaTask } from './types/models';
import type { State } from './types/state';

type Params = {|
|};

type Props = Params & {|
  // Action creators
  clearCaseSelectSearch: typeof clearCaseSelectSearch
|};

class ColocatedTaskListView extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  pageNew = () => {
    return <NewTasksTab />;
  }

  pageOnHold = () => {
    return <OnHoldTasksTab />;
  }

  render = () => {
    const tabs = [{
      label: 'New',
      page: <NewTasksTab />
    }, {
      label: 'On hold',
      page: this.pageOnHold()
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

const NewTasksTab = connect(
  (state: State) => ({ tasks: amaTasksNewByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<AmaTask> }) => {
    return <div>
      <p>{COPY.COLOCATED_QUEUE_PAGE_NEW_TASKS_DESCRIPTION}</p>
      <AmaTaskTable tasks={props.tasks} includeDaysWaiting />
    </div>;
  });

const OnHoldTasksTab = connect(
  (state: State) => ({ tasks: amaTasksOnHoldByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<AmaTask> }) => {
    return <div>
      <p>{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <AmaTaskTable tasks={props.tasks} includeDaysOnHold />
    </div>;
  });
