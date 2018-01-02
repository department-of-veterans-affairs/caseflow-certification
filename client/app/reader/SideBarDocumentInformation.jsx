import React, { PureComponent } from 'react';
import { formatDateStr } from '../util/DateUtil';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import IssueList from './IssueList';
import TextField from '../components/TextField';
import { saveDocumentDescription, changeDocumentDescription } from './Documents/DocumentsActions';

import LoadingMessage from '../components/LoadingMessage';
import { getClaimTypeDetailInfo } from '../reader/utils';
import Alert from '../components/Alert';

class SideBarDocumentInformation extends PureComponent {
  render() {
    const { appeal } = this.props;
    let renderComponent;

    const reload = () => {
      window.location.href = window.location.href;
    };

    if (this.props.didLoadAppealFail) {
      renderComponent = <Alert
        title="Unable to retrieve claim details"
        type="error">
        Please <a href="#" onClick={reload}>
        refresh this page</a> or try again later.
      </Alert>;
    } else if (_.isEmpty(appeal)) {
      renderComponent = <LoadingMessage message="Loading details..." />;
    } else {
      renderComponent = <div>
        <p className="cf-pdf-meta-title">
          <strong>Veteran ID:</strong> {appeal.vbms_id}
        </p>
        <p className="cf-pdf-meta-title">
          <strong>Type:</strong> {appeal.type} {getClaimTypeDetailInfo(appeal)}
        </p>
        <p className="cf-pdf-meta-title">
          <strong>Docket Number:</strong> {appeal.docket_number}
        </p>
        <p className="cf-pdf-meta-title">
          <strong>Regional Office:</strong> {`${appeal.regional_office.key} - ${appeal.regional_office.city}`}
        </p>
        <div className="cf-pdf-meta-title">
          <strong>Issues: </strong>
          <IssueList appeal={appeal} className="cf-pdf-meta-doc-info-issues" />
        </div>
      </div>;
    }

    return <div className="cf-sidebar-document-information">
      <p className="cf-pdf-meta-title cf-pdf-cutoff">
        <strong>Document Type: </strong>
        <span title={this.props.doc.type} className="cf-document-type">
          {this.props.doc.type}
        </span>
      </p>
      <span className="cf-pdf-meta-title">
        <TextField
          label="Document Description:"
          strongLabel
          name="document_description"
          className={['cf-inline-field']}
          value={this.props.doc.description}
          onBlur={this.saveDocDescription}
          onChange={this.changePendingDocDescription}
          maxLength={50}
          errorMessage={this.props.error.visible ? this.props.error.message : undefined}
        />
      </span>
      <p className="cf-pdf-meta-title">
        <strong>Receipt Date:</strong> {formatDateStr(this.props.doc.receivedAt)}
      </p>
      <hr />
      {renderComponent}
    </div>;
  }

  changePendingDocDescription = (description) => this.props.changeDocumentDescription(this.props.doc.id, description);
  saveDocDescription = (description) => this.props.saveDocumentDescription(this.props.doc.id, description);
}

SideBarDocumentInformation.propTypes = {
  appeal: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  didLoadAppealFail: state.pdfViewer.didLoadAppealFail,
  error: state.pdfViewer.pdfSideBarError.description
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    changeDocumentDescription,
    saveDocumentDescription
  }, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SideBarDocumentInformation);

