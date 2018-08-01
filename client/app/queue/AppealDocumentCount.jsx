import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';

import { setAppealDocCount } from './QueueActions';

class AppealDocumentCount extends React.PureComponent {
  componentDidMount = () => {
    const appeal = this.props.appeal.attributes;

    if (appeal.paper_case) {
      return;
    }

    if (!this.props.docCountForAppeal) {
      const requestOptions = {
        withCredentials: true,
        timeout: true
      };

      ApiUtil.get(`/appeals/${appeal.external_id}/document_count`, requestOptions).then((response) => {
        const resp = JSON.parse(response.text);

        this.props.setAppealDocCount(appeal.external_id, resp.document_count);
      });
    }
  }

  render = () => this.props.docCountForAppeal;
}

AppealDocumentCount.propTypes = {
  appeal: PropTypes.object.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  docCountForAppeal: state.queue.docCountForAppeal[ownProps.appeal.attributes.external_id] || null
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
