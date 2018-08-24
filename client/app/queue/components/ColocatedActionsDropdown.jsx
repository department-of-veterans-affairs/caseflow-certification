// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import { getTasksForAppeal } from '../selectors';
import {
  stageAppeal,
  checkoutStagedAppeal
} from '../QueueActions';
import { showModal } from '../uiReducer/uiActions';

import {
  dropdownStyling,
  COLOCATED_ACTIONS,
  SEND_TO_LOCATION_MODAL_TYPES
} from '../constants';
import CO_LOCATED_ACTIONS from '../../../constants/CO_LOCATED_ACTIONS.json';
import COPY from '../../../COPY.json';

import type { State } from '../types/state';
import type { Task } from '../types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // state
  task: Task,
  // dispatch
  showModal: typeof showModal,
  stageAppeal: typeof stageAppeal,
  checkoutStagedAppeal: typeof checkoutStagedAppeal,
  // withrouter
  history: Object
|};

class ColocatedActionsDropdown extends React.PureComponent<Props> {
  onChange = (props) => {
    const {
      appealId,
      history
    } = this.props;
    const actionType = props.value;

    this.props.stageAppeal(appealId);

    switch (actionType) {
    case CO_LOCATED_ACTIONS.SEND_BACK_TO_ATTORNEY:
      return this.props.showModal(SEND_TO_LOCATION_MODAL_TYPES.attorney);
    case CO_LOCATED_ACTIONS.SEND_TO_TEAM: {
      return this.props.showModal(SEND_TO_LOCATION_MODAL_TYPES.team);
    }
    case CO_LOCATED_ACTIONS.PLACE_HOLD:
      history.push(`/queue/appeals/${appealId}/place_hold`);
      break;
    default:
      break;
    }
  }

  getOptions = () => {
    const { task } = this.props;

    if (task.status !== 'on_hold') {
      return [...COLOCATED_ACTIONS, {
        label: COPY.COLOCATED_ACTION_PLACE_HOLD,
        value: CO_LOCATED_ACTIONS.PLACE_HOLD
      }];
    }

    return COLOCATED_ACTIONS;
  }

  render = () => <SearchableDropdown
    name={`start-colocated-action-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={this.getOptions()}
    onChange={this.onChange}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showModal,
  stageAppeal,
  checkoutStagedAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ColocatedActionsDropdown)
): React.ComponentType<Params>);
