import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import querystring from 'querystring';
import { css } from 'glamor';

import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { TASK_ACTIONS } from './constants';
const disabledLinkStyle = css({ color: COMMON_COLORS.GREY_MEDIUM });

class ReaderLink extends React.PureComponent {

  readerLinkAnalytics = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.QUEUE_TO_READER);
  }

  getLinkText = () => {
    const {
      message,
      docCount
    } = this.props;

    let linkText = 'View in Reader';

    if (message) {
      linkText = message;
    } else if (_.isNumber(docCount)) {
      linkText = `View ${docCount.toLocaleString()} in Reader`;
    }

    return linkText;
  };

  render = () => {
    const {
      redirectUrl,
      taskType,
      task_id: taskId,
      vacols_id: vacolsId
    } = this.props;

    if (!taskId) {
      return <span {...disabledLinkStyle}>
        {this.getLinkText()}
      </span>;
    }

    const queryParams = {
      queue_redirect_url: redirectUrl
    };

    if (taskType) {
      queryParams.queue_task_type = taskType;
    }
    const qs = querystring.stringify(queryParams);
    const href = `/reader/appeal/${vacolsId}/documents?${qs}`;

    return <Link href={href}
      onClick={this.readerLinkAnalytics}>
      {this.getLinkText()}
    </Link>;
  };
}

ReaderLink.propTypes = {
  analyticsSource: PropTypes.string,
  redirectUrl: PropTypes.string,
  taskType: PropTypes.string,
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  ..._.pick(state.queue.loadedQueue.tasks[ownProps.vacolsId].attributes, 'task_id'),
  ..._.pick(state.queue.loadedQueue.appeals[ownProps.vacolsId].attributes, 'docCount', 'vacols_id')
});

export default connect(mapStateToProps)(ReaderLink);
