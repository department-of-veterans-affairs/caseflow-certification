import React from 'react';
import COPY from '../../../COPY.json';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import RadioField from '../../components/RadioField';
import Button from '../../components/Button';
import BasicDateRangeSelector from '../../components/BasicDateRangeSelector';
import FileUpload from '../../components/FileUpload';
import InlineForm from '../../components/InlineForm';
import { SPREADSHEET_TYPES, ERROR_MAPPINGS } from '../constants';
import { formatDateStr } from '../../util/DateUtil';
import moment from 'moment';


const fileUploadStyling = css({
  marginTop: '70px'
});

export default class BuildScheduleUpload extends React.Component {

  getDate = (date) => {
    return moment(date).format('MM-DD-YYYY');
  }

  getErrorMessage = (errors) => {
    return <div className="usa-input-error">We have found the following errors with your upload. Please
      check the file and dates and try again.
      <ul>
        {_.map(errors.replace('Validation failed: ', '').split(', '), (error, i) => {
          return ERROR_MAPPINGS[error] ? <li key={i}>{ERROR_MAPPINGS[error]}</li> : null;
        })}
      </ul>
    </div>;
  };

  getRoCoDisplay = () => {
    return <div>{ SPREADSHEET_TYPES.RoSchedulePeriod.display }
      { this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value &&
      <div>
        {this.props.uploadRoCoFormErrors &&
          <span className="usa-input-error-message">{this.getErrorMessage(this.props.uploadRoCoFormErrors)}</span>}
        <InlineForm>
          <BasicDateRangeSelector
            messageLabel
            startDateName="startDate"
            startDateValue={this.getDate(this.props.roCoStartDate)}
            startDateLabel={false}
            endDateName="endDate"
            endDateValue={this.props.roCoEndDate}
            endDateLabel={false}
            onStartDateChange={this.props.onRoCoStartDateChange}
            onEndDateChange={this.props.onRoCoEndDateChange}
          />
          <div {...fileUploadStyling} >
            <FileUpload {...fileUploadStyling}
              preUploadText="Select a file for upload"
              postUploadText="Choose a different file"
              id="ro_co_file_upload"
              fileType=".xlsx"
              onChange={this.props.onRoCoFileUpload}
              value={this.props.roCoFileUpload}
            />
          </div>
        </InlineForm>
      </div>}
    </div>;
  };

  getJudgeDisplay = () => {
    return <div>{ SPREADSHEET_TYPES.JudgeSchedulePeriod.display }
      { this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value &&
      <div>
        {this.props.uploadJudgeFormErrors &&
          <span className="usa-input-error-message">{this.getErrorMessage(this.props.uploadJudgeFormErrors)}</span>}
        <InlineForm>
          <BasicDateRangeSelector
            messageLabel
            startDateName="startDate"
            startDateValue={this.props.judgeStartDate}
            startDateLabel={false}
            endDateName="endDate"
            endDateValue={this.props.judgeEndDate}
            endDateLabel={false}
            onStartDateChange={this.props.onJudgeStartDateChange}
            onEndDateChange={this.props.onJudgeEndDateChange}
          />
          <div {...fileUploadStyling} >
            <FileUpload
              preUploadText="Select a file for upload"
              postUploadText="Choose a different file"
              id="judge_file_upload"
              fileType=".xlsx"
              onChange={this.props.onJudgeFileUpload}
              value={this.props.judgeFileUpload}
            />
          </div>
        </InlineForm>
      </div>}
    </div>;
  };

  render() {
    const fileTypes = [
      {
        value: SPREADSHEET_TYPES.RoSchedulePeriod.value,
        displayText: this.getRoCoDisplay()
      },
      {
        value: SPREADSHEET_TYPES.JudgeSchedulePeriod.value,
        displayText: this.getJudgeDisplay()
      }
    ];

    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_UPLOAD_PAGE_HEADER}</h1>
      <p>{COPY.HEARING_SCHEDULE_UPLOAD_PAGE_INSTRUCTIONS}</p>
      <div className="cf-help-divider"></div>
      <RadioField
        name={COPY.HEARING_SCHEDULE_UPLOAD_PAGE_RADIO_FIELD_HEADER}
        options={fileTypes}
        value={this.props.fileType}
        onChange={this.props.onFileTypeChange}
        errorMessage={this.props.uploadFormErrors}
        required
        vertical
        strongLabel
      />
      <Link
        name="cancel"
        to="/schedule/build">
        Cancel
      </Link>
      <div className="cf-push-right">
        <Button
          name="continue"
          button="primary"
          loading={this.props.uploadContinueLoading}
          onClick={this.props.onUploadContinue}
        >
          Continue
        </Button>
      </div>
    </AppSegment>;
  }
}

BuildScheduleUpload.propTypes = {
  fileType: PropTypes.string,
  onFileTypeChange: PropTypes.func,
  roCoStartDate: PropTypes.string,
  roCoEndDate: PropTypes.string,
  onRoCoStartDateChange: PropTypes.func,
  onRoCoEndDateChange: PropTypes.func,
  roCoFileUpload: PropTypes.object,
  onRoCoFileUpload: PropTypes.func,
  judgeStartDate: PropTypes.string,
  judgeEndDate: PropTypes.string,
  onJudgeStartDateChange: PropTypes.func,
  onJudgeEndDateChange: PropTypes.func,
  judgeFileUpload: PropTypes.object,
  onJudgeFileUpload: PropTypes.func,
  uploadFormErrors: PropTypes.string,
  uploadRoCoFormErrors: PropTypes.string,
  uploadJudgeFormErrors: PropTypes.string,
  onUploadContinue: PropTypes.func,
  uploadContinueLoading: PropTypes.bool
};
