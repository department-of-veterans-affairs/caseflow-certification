// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  stageAppeal,
  checkoutStagedAppeal
} from '../QueueActions';
import { showModal } from '../uiReducer/uiActions';

import {
  dropdownStyling,
  COLOCATED_ACTIONS
} from '../constants';
import CO_LOCATED_ACTIONS from '../../../constants/CO_LOCATED_ACTIONS.json';

import type { State } from '../types/state';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // state
  changedAppeals: Array<number>,
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

    if (actionType === CO_LOCATED_ACTIONS.SEND_BACK_TO_ATTORNEY) {
      return this.props.showModal('sendToAttorney');
    }

    const route = {
      [CO_LOCATED_ACTIONS.SEND_TO_TEAM]: 'send_to_team',
      [CO_LOCATED_ACTIONS.PLACE_HOLD]: 'place_hold'
    }[actionType];

    history.push(`/queue/appeals/${appealId}/${route}`);
  }

  render = () => <SearchableDropdown
    name={`start-colocated-action-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={COLOCATED_ACTIONS}
    onChange={this.onChange}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

const mapStateToProps = (state: State) => ({
  changedAppeals: Object.keys(state.queue.stagedChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showModal,
  stageAppeal,
  checkoutStagedAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ColocatedActionsDropdown)
): React.ComponentType<Params>);
