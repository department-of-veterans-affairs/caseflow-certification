import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import { LOADING_INDICATOR_COLOR_DEFAULT } from '../constants/AppConstants';
import moment from 'moment';

// This may go away in favor of the timestamp from updated record
const now = () => {
  return moment().
    format('h:mm a').
    replace(/(p|a)m/, '$1.m.');
};

export class AutoSave extends React.Component {

  componentDidMount = () => {
    if (!window.onbeforeunload) {
      window.onbeforeunload = () => {
        this.props.saveBeforeWindowCloses();
      };
    }
  }

  render() {
    const color = this.props.spinnerColor || LOADING_INDICATOR_COLOR_DEFAULT;

    if (this.props.isSaving) {
      return <div className="saving">Saving...
        <div className="loadingSymbol">{loadingSymbolHtml('', '100%', color)}</div>
      </div>;
    }

    return <span className="saving">Last saved at {now()}</span>;
  }
}

// If isSaving is not on the state, use whatever was passed into the component.
// VERY convenient for unit testing.
const mapStateToProps = (state, ownProps) => ({
  isSaving: typeof state.isSaving === 'undefined' ? ownProps.isSaving : state.isSaving
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  saveBeforeWindowCloses: () => {
    dispatch(ownProps.beforeWindowClosesActionCreator());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AutoSave);

AutoSave.propTypes = {
  isSaving: PropTypes.bool,
  spinnerColor: PropTypes.string,
  beforeWindowClosesActionCreator: PropTypes.func
};
