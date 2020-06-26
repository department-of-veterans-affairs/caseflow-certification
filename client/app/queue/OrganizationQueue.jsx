import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';
import Alert from '../components/Alert';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

const containerStyles = css({
  position: 'relative'
});

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const { success } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} />}
      <QueueTableBuilder />
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  clearCaseSelectSearch: PropTypes.func,
  success: PropTypes.object
};

const mapStateToProps = (state) => ({ success: state.ui.messages.success });

const mapDispatchToProps = (dispatch) => ({ ...bindActionCreators({ clearCaseSelectSearch }, dispatch) });

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);
