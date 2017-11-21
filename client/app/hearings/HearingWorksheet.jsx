import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import moment from 'moment';
import Link from '../components/Link';
import TextField from '../components/TextField';
import Textarea from 'react-textarea-autosize';
import HearingWorksheetStream from './components/HearingWorksheetStream';
import AutoSave from '../components/AutoSave';
import * as AppConstants from '../constants/AppConstants';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';
import { saveIssues } from './actions/Issue';

import {
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  setWorksheetSaveFailedStatus,
  saveWorksheet
} from './actions/Dockets';

class WorksheetFormEntry extends React.PureComponent {
  render() {
    const textAreaProps = {
      minRows: 3,
      maxRows: 5000,
      ...this.props
    };

    return <div className="cf-hearings-worksheet-data">
      <label htmlFor={this.props.id}>{this.props.name}</label>
      {this.props.print ? 
        <p>{this.props.value}</p> : 
        <Textarea {...textAreaProps} />}
    </div>;
  }
}

export class HearingWorksheet extends React.PureComponent {

  save = (worksheet, worksheetIssues) => () => {
    this.props.toggleWorksheetSaving();
    this.props.setWorksheetSaveFailedStatus(false);
    this.props.saveWorksheet(worksheet);
    this.props.saveIssues(worksheetIssues);
    this.props.toggleWorksheetSaving();
  };

  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);
  onContentionsChange = (event) => this.props.onContentionsChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);
  onEvidenceChange = (event) => this.props.onEvidenceChange(event.target.value);
  onCommentsForAttorneyChange = (event) => this.props.onCommentsForAttorneyChange(event.target.value);

  render() {
    let { worksheet, worksheetIssues } = this.props;
    let readerLink = `/reader/appeal/${worksheet.appeal_vacols_id}/documents`;

    const appellant = worksheet.appellant_mi_formatted ?
      worksheet.appellant_mi_formatted : worksheet.veteran_mi_formatted;

    return <div>
      <div className="cf-app-segment--alt cf-hearings-worksheet">

        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Hearing Worksheet</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(worksheet.date).format('ddd l')}</div>
            <div>Hearing Type: {worksheet.request_type}</div>
          </div>
        </div>

        <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Appellant/Veteran Information</h2>
          <AutoSave
            save={this.save(worksheet, worksheetIssues)}
            spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
            isSaving={this.props.worksheetIsSaving}
            saveFailed={this.props.saveWorksheetFailed}
          />
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Appellant Name:</div>
            <div><b>{appellant}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>City/State:</div>
            <div>{worksheet.appellant_city}, {worksheet.appellant_state}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Regional Office:</div>
            <div>{worksheet.regional_office_name}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>Representative Org:</div>
            <div>{worksheet.representative}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-5">
            <TextField
              name="Rep. Name:"
              id="appellant-vet-rep-name"
              aria-label="Representative Name"
              value={worksheet.representative_name || ''}
              onChange={this.props.onRepNameChange}
              maxLength={30}
              hideInput={this.props.print}
            />
          </div>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Veteran Name:</div>
            <div><b>{worksheet.veteran_mi_formatted}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>Veteran ID:</div>
            <div><b>{worksheet.vbms_id}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Veteran's Age:</div>
            <div>{worksheet.veteran_age}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
          </div>
          <div className="cf-hearings-worksheet-data-cell cf-hearings-worksheet-witness-cell column-5">
            <label htmlFor="appellant-vet-witness">Witness (W)/Observer (O):</label>
            {!this.props.print &&
              <Textarea
                name="Witness (W)/Observer (O):"
                id="appellant-vet-witness"
                aria-label="Witness Observer"
                value={worksheet.witness || ''}
                onChange={this.onWitnessChange}
                maxLength={120}
              />
            }
          </div>
        </div>

        <HearingWorksheetDocs
          {...this.props}
        />

        <HearingWorksheetStream
          {...this.props}
          print={this.props.print}
        />

        <form className="cf-hearings-worksheet-form">
          <WorksheetFormEntry
            name="Periods and circumstances of service"
            value={worksheet.military_service}
            onChange={this.onMilitaryServiceChange}
            id="worksheet-military-service"
            minRows={1}
            print={this.props.print}
          />
          <WorksheetFormEntry
            name="Contentions"
            value={worksheet.contentions}
            onChange={this.onContentionsChange}
            id="worksheet-contentions"
            print={this.props.print}
          />
          <WorksheetFormEntry
            name="Evidence"
            value={worksheet.evidence}
            onChange={this.onEvidenceChange}
            id="worksheet-evidence"
            print={this.props.print}
          />
          <WorksheetFormEntry
            name="Comments and special instructions to attorneys"
            value={worksheet.comments_for_attorney}
            id="worksheet-comments-for-attorney"
            onChange={this.onCommentsForAttorneyChange}
            print={this.props.print}
          />
        </form>
      </div>
      {!this.props.print &&
      <div className="cf-push-right">
        <Link href={`${window.location.pathname}/print`} button="secondary" target="_blank">
          Save as PDF
        </Link>
        <Link
          name="review-efolder"
          href={`${readerLink}?category=case_summary`}
          button="primary"
          target="_blank">
            Review eFolder</Link>
      </div>
      }
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet,
  worksheetIssues: state.worksheetIssues,
  worksheetAppeals: state.worksheetAppeals
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  saveWorksheet,
  setWorksheetSaveFailedStatus,
  saveIssues
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
