// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';

import decisionViewBase from './components/DecisionViewBase';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { requestSave } from './uiReducer/uiActions';
import { deleteAppeal } from './QueueActions';

import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';
import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import type { LegacyAppeal } from './types/models';
import type { UiStateError } from './types/state';

type State = {|
  title: ?string,
  instructions: string
|};

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // store
  highlightFormItems: boolean,
  error: ?UiStateError,
  appeal: LegacyAppeal,
  // dispatch
  requestSave: typeof requestSave,
  deleteAppeal: typeof deleteAppeal
|};

class AddAdminActionView extends React.PureComponent<Props, State> {
  constructor(props) {
    super(props);

    this.state = {
      title: null,
      instructions: ''
    };
  }

  validateForm = () => _.every(Object.values(this.state), (val) => !!val);

  getPrevStepUrl = () => `/queue/appeals/${this.props.appealId}`;

  goToNextStep = () => {
    const payload = {
      data: {
        tasks: [{
          ...this.state,
          type: 'ColocatedTask',
          appeal_id: this.props.appeal.id
        }]
      }
    };
    const successMsg = 'success message';

    this.props.requestSave('/tasks', payload, successMsg).
      then(() => this.props.deleteAppeal(this.props.appealId));
  }

  render = () => {
    const { highlightFormItems, error } = this.props;
    const { title, instructions } = this.state;

    return <React.Fragment>
    <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
      {COPY.ADD_ADMIN_ACTION_SUBHEAD}
    </h1>
    <hr />
    {error && <Alert title={error.title} type="error">
      {error.detail}
    </Alert>}
    <div {...marginTop(4)}>
      <SearchableDropdown
        errorMessage={highlightFormItems && !title ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
        name={COPY.ADD_ADMIN_ACTION_ACTION_TYPE_LABEL}
        placeholder="Select an action type"
        options={_.map(CO_LOCATED_ADMIN_ACTIONS, (label: string, value: string) => ({
          label,
          value
        }))}
        onChange={({ value }) => this.setState({ title: value })}
        value={this.state.title} />
    </div>
    <div {...marginTop(4)}>
      <TextareaField
        errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
        name={COPY.ADD_ADMIN_ACTION_INSTRUCTIONS_LABEL}
        onChange={(instructions) => this.setState({ instructions })}
        value={this.state.instructions} />
    </div>
  </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => ({
  highlightFormItems: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  appeal: state.queue.appeals[ownProps.appealId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  deleteAppeal
}, dispatch);

const WrappedComponent = decisionViewBase(AddAdminActionView, {
  hideCancelButton: true,
  continueBtnText: 'Assign Action'
});
export default (connect(mapStateToProps, mapDispatchToProps)(WrappedComponent): React.ComponentType<Params>);
