import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ReviewAssignments from '../components/ReviewAssignments';
import {
  onReceiveSchedulePeriod,
  onClickConfirmAssignments,
  onClickCloseModal,
  onConfirmAssignmentsUpload
} from '../actions';

export class ReviewAssignmentsContainer extends React.Component {

  onConfirmAssignmentsUpload = () => {
    this.props.onClickCloseModal();
    this.props.onConfirmAssignmentsUpload();
    this.props.history.push('/schedule/build');
  };

  loadSchedulePeriod = () => {
    return ApiUtil.get(`/hearings/schedule_periods/${this.props.match.params.schedulePeriodId}`).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
      const schedulePeriod = resp.schedulePeriod;

      this.props.onReceiveSchedulePeriod(schedulePeriod);
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadSchedulePeriod()
  ]);

  render() {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'We are assigning hearings...'
      }}
      failStatusMessageProps={{
        title: 'Unable to assign hearings. Please try again.'
      }}>
      <ReviewAssignments
        schedulePeriod={this.props.schedulePeriod}
        onClickConfirmAssignments={this.props.onClickConfirmAssignments}
        onClickCloseModal={this.props.onClickCloseModal}
        displayConfirmationModal={this.props.displayConfirmationModal}
        onConfirmAssignmentsUpload={this.onConfirmAssignmentsUpload}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  schedulePeriod: state.schedulePeriod,
  displayConfirmationModal: state.displayConfirmationModal
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveSchedulePeriod,
  onClickConfirmAssignments,
  onClickCloseModal,
  onConfirmAssignmentsUpload
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ReviewAssignmentsContainer));
