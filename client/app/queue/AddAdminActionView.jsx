// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import decisionViewBase from './components/DecisionViewBase';
import TextAreaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';

import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';

import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

type State = {|
  admin_action: ?string,
  instructions: string
|};

type Params = {|
  appealId: string
|};

type Props = Params & {||};

class AddAdminActionView extends React.PureComponent<Props, State> {
  constructor(props) {
    super(props);

    this.state = {
      admin_action: null,
      instructions: ''
    };
  }

  render = () => <React.Fragment>
    <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
      {COPY.ADD_ADMIN_ACTION_SUBHEAD}
    </h1>
    <hr />
    <div {...marginTop(4)}>
      <SearchableDropdown
        required
        name={COPY.ADD_ADMIN_ACTION_ACTION_TYPE_LABEL}
        placeholder="Select an action type"
        options={_.map(CO_LOCATED_ADMIN_ACTIONS, (label: string, value: string) => ({
          label,
          value
        }))}
        onChange={({ value }) => this.setState({ admin_action: value })}
        value={this.state.admin_action} />
    </div>
    <div {...marginTop(4)}>
      <TextAreaField
        name={COPY.ADD_ADMIN_ACTION_INSTRUCTIONS_LABEL}
        onChange={({ value }) => this.setState({ instructions: value })}
        value={this.state.instructions} />
    </div>
  </React.Fragment>;
}

const WrappedComponent = decisionViewBase(AddAdminActionView, {
  title: 'cancelAddAdminAction',
  text: 'asdfasdfasdf'
});
export default (connect(null, null)(WrappedComponent): React.ComponentType<Params>);
