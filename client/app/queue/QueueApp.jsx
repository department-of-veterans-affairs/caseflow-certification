import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import Breadcrumbs from './components/BreadcrumbManager';
import QueueLoadingScreen from './QueueLoadingScreen';
import AttorneyTaskListView from './AttorneyTaskListView';
import JudgeTaskListView from './JudgeTaskListView';

import QueueDetailView from './QueueDetailView';
import SearchEnabledView from './SearchEnabledView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';

import { LOGO_COLORS } from '../constants/AppConstants';
import { DECISION_TYPES } from './constants';

const appStyling = css({ paddingTop: '3rem' });

class QueueApp extends React.PureComponent {
  routedQueueList = () => <QueueLoadingScreen {...this.props}>
    <SearchEnabledView
      feedbackUrl={this.props.feedbackUrl}
      shouldUseQueueCaseSearch={this.props.featureToggles.queue_case_search}>
      {this.props.userRole === 'Attorney' ?
        <AttorneyTaskListView {...this.props} /> :
        <JudgeTaskListView {...this.props} />
      }
    </SearchEnabledView>
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props}>
    <Breadcrumbs />
    <QueueDetailView
      vacolsId={props.match.params.vacolsId}
      featureToggles={this.props.featureToggles} />
  </QueueLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    vacolsId={props.match.params.vacolsId}
    nextStep="/" />;

  routedSelectDispositions = (props) => {
    const { vacolsId } = props.match.params;

    return <SelectDispositionsView
      vacolsId={vacolsId}
      prevStep={`/appeals/${vacolsId}`}
      nextStep={`/appeals/${vacolsId}/submit`} />;
  };

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/appeals/${props.match.params.vacolsId}/dispositions`}
    prevStep={`/appeals/${props.match.params.vacolsId}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView
    nextStep={`/appeals/${props.match.params.appealId}/submit`}
    {...props.match.params} />;

  render = () => <BrowserRouter basename="/queue">
    <NavigationBar
      wideApp
      defaultUrl="/"
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT
      }}
      appName="">
      <AppFrame wideApp>
        <div className="cf-wide-app" {...appStyling}>
          <PageRoute
            exact
            path="/"
            title="Your Queue | Caseflow"
            render={this.routedQueueList} />
          <PageRoute
            exact
            path="/appeals/:vacolsId"
            title="Case Details | Caseflow"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path="/appeals/:vacolsId/submit"
            title={() => {
              const reviewActionType = this.props.reviewActionType === DECISION_TYPES.OMO_REQUEST ?
                'OMO' : 'Draft Decision';

              return `Draft Decision | Submit ${reviewActionType}`;
            }}
            render={this.routedSubmitDecision} />
          <PageRoute
            exact
            path="/appeals/:vacolsId/dispositions/:action(add|edit)/:issueId?"
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/appeals/:appealId/remands"
            title="Draft Decision | Select Issue Remand Reasons"
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/appeals/:vacolsId/dispositions"
            title="Draft Decision | Select Dispositions"
            render={this.routedSelectDispositions} />
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName=""
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate} />
    </NavigationBar>
  </BrowserRouter>;
}

QueueApp.propTypes = {
  userDisplayName: PropTypes.string.isRequired,
  feedbackUrl: PropTypes.string.isRequired,
  userId: PropTypes.number.isRequired,
  userRole: PropTypes.string.isRequired,
  dropdownUrls: PropTypes.array,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => ({
  ..._.pick(state.caseSelect, 'caseSelectCriteria.searchQuery'),
  ..._.pick(state.queue.loadedQueue, 'appeals'),
  reviewActionType: state.queue.stagedChanges.taskDecision.type
});

export default connect(mapStateToProps)(QueueApp);
