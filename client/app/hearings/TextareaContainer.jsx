import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';

export class TextareaContainer extends React.Component {

  updateTextarea = (event) => {
    this.props.updateTextarea(this.props.action, event.target.id, event.target.value);
  }

  render() {
    return <textarea
      id={this.props.id}
      defaultValue={this.props[this.props.id] || this.props.defaultValue || ''}
      onChange={this.updateTextarea}
      maxLength={this.props.maxLength}
      tabIndex={this.props.tabIndex}
    />;
  }
}

const mapStateToProps = (state, ownProps) => ({
  [ownProps.id]: state[ownProps.id]
});

const mapDispatchToProps = (dispatch) => ({
  updateTextarea: (actionName, prop, value) => {
    let action = Actions[actionName];

    dispatch(action(prop, value));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(TextareaContainer);

TextareaContainer.propTypes = {
  id: PropTypes.string.isRequired
};
