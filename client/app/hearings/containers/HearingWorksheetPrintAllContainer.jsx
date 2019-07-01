import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../util/ApiUtil';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import HearingWorksheetPrinted from '../components/hearingWorksheet/HearingWorksheetPrinted';

const failedToLoad = <div><p>Failed to load</p></div>;

class HearingWorksheetPrintAllContainer extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      worksheets: []
    };
  }

  blergh = (response) => {
    const worksheet = response.body;
    const worksheetAppeals = _.keyBy(worksheet.appeals_ready_for_hearing, 'id');
    let worksheetIssues = _(worksheetAppeals).flatMap('worksheet_issues').
      keyBy('id').
      value();

    if (_.isEmpty(worksheetIssues)) {
      worksheetIssues = _.keyBy(worksheet.worksheet_issues, 'id');
    }

    return {
      worksheet,
      worksheetAppeals,
      worksheetIssues
    };
  }

  loadHearingWorksheets = () => {
    let { hearingIds } = this.props;
    let getAllWorksheets = hearingIds.map(
      (hearingId) => ApiUtil.get(`/hearings/${hearingId}/worksheet.json`)
    );

    return Promise.all(getAllWorksheets).then((responses) => {
      this.setState({ worksheets: responses.map(this.blergh) });
    });
  };

  render() {
    return (
      <React.Fragment>
        <LoadingDataDisplay
          createLoadPromise={this.loadHearingWorksheets}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
            message: 'Loading the hearing worksheet...'
          }}
          failStatusMessageProps={{
            title: 'Unable to load the hearing worksheet.'
          }}
          failStatusMessageChildren={failedToLoad}
        >
          {
            this.state.worksheets &&
            this.state.worksheets.map(
              (worksheet) => (
                <div className="cf-printed-worksheet" key={worksheet.worksheet.id}>
                  <HearingWorksheetPrinted {...worksheet} />
                </div>
              )
            )
          }
        </LoadingDataDisplay>
      </React.Fragment>
    );
  }
}

HearingWorksheetPrintAllContainer.propTypes = {
  hearingIds: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default HearingWorksheetPrintAllContainer;
