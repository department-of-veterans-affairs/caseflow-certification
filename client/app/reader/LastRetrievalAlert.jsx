import _ from 'lodash';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';
import Alert from '../components/Alert';

const CACHE_TIMEOUT_HOURS = 3;
const TIMEZONES = {
  ' GMT': ' +0000',
  ' EDT': ' -0400',
  ' EST': ' -0500',
  ' CDT': ' -0500',
  ' CST': ' -0600',
  ' MDT': ' -0600',
  ' MST': ' -0700',
  ' PDT': ' -0700',
  ' PST': ' -0800'
};

class LastRetrievalAlert extends React.PureComponent {

  render() {

    // Check that document manifests have been recieved from VVA and VBMS
    if (!this.props.manifestVbmsFetchedAt || !this.props.manifestVvaFetchedAt) {
      return <Alert title="Error" type="error">
        Some of {this.props.appeal.veteran_full_name}'s documents are not available at the moment due to
        a loading error from VBMS or VVA. As a result, you may be viewing a partial list of claims folder documents.
        <br />
        <br />
        Please refresh your browser at a later point to view a complete list of documents in the claims
        folder.
      </Alert>;
    }

    let staleCacheTime = new Date();

    staleCacheTime.setHours(staleCacheTime.getHours() - CACHE_TIMEOUT_HOURS);

    const staleCacheTimestamp = staleCacheTime.getTime() / 1000,
      vbmsManifestTimeString = this.props.manifestVbmsFetchedAt,
      vvaManifestTimeString = this.props.manifestVvaFetchedAt;

    const parsableVbmsManifestTimeString = vbmsManifestTimeString.slice(0, -4) +
      TIMEZONES[vbmsManifestTimeString.slice(-4)],
      parsableVvaManifestTimeString = vvaManifestTimeString.slice(0, -4) +
        TIMEZONES[vvaManifestTimeString.slice(-4)],
      vbmsManifestTimestamp = moment(parsableVbmsManifestTimeString, 'MM/DD/YY HH:mma Z').unix(),
      vvaManifestTimestamp = moment(parsableVvaManifestTimeString, 'MM/DD/YY HH:mma Z').unix();

    // Check that manifest results are fresh
    if (vbmsManifestTimestamp < staleCacheTimestamp || vvaManifestTimestamp < staleCacheTimestamp) {
      return <Alert title="Warning" type="warning">
        You may be viewing an outdated list of claims folder documents. Please refresh the page to load
        the most up to date documents.
      </Alert>;
    }

    return null;
  }
}

export default connect(
  (state) => _.pick(state.documentList, ['manifestVvaFetchedAt', 'manifestVbmsFetchedAt'])
)(LastRetrievalAlert);
