import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import moment from 'moment-timezone';
import { formatDateStr } from '../../util/DateUtil';
import { changeReasons } from './EditNodDateModal';

import COPY from 'app/../COPY';
import { GreenCheckmark } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { grayLineTimelineStyling } from './TaskRows';

const nodDateUpdateTimelineTimeStyling = css({
  color: COLORS.GREY_MEDIUM,
  fontSize: '15px'
});

const nodDateUpdateTimelineInfoStyling = css({
  display: 'flex',
  flexWrap: 'wrap',
  '& *': {
    whiteSpace: 'nowrap',
    marginRight: '1rem',
  },
  '& span': {
    color: COLORS.GREY_MEDIUM,
    fontSize: '1.5rem',
    marginRight: '0.5rem',
    textTransform: 'uppercase'
  }
});

export const NodDateUpdateTimeline = (props) => {
  const { nodDateUpdate, timeline } = props;
  const changeReason = changeReasons.find((reason) => reason.value === nodDateUpdate.changeReason).label;

  return <React.Fragment>
    {timeline && <tr>
      <td className="taskContainerStyling taskTimeTimelineContainerStyling">
        <div>{ moment(nodDateUpdate.closedAt).format('MM/DD/YYYY') }</div>
        <div {...nodDateUpdateTimelineTimeStyling}>
          { moment(nodDateUpdate.closedAt).tz('America/New_York').
            format('HH:mm:ss') } EST
        </div>
      </td>
      <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
        <GreenCheckmark />
        <div {...grayLineTimelineStyling} />
      </td>
      <td className="taskContainerStyling taskInformationTimelineContainerStyling">
        { COPY.CASE_TIMELINE_NOD_DATE_UPDATE }
        <div {...nodDateUpdateTimelineInfoStyling}>
          <div><span>Edited:</span>{nodDateUpdate.userFirstName.split('')[0]}. {nodDateUpdate.userLastName}</div>
          <div><span>Old Nod:</span>{formatDateStr(nodDateUpdate.oldDate)}</div>
          <div><span>New Nod:</span>{formatDateStr(nodDateUpdate.newDate)}</div>
          <div><span>Reason:</span>{changeReason}</div>
        </div>
      </td>
    </tr>
    }
  </React.Fragment>;
};

NodDateUpdateTimeline.propTypes = {
  nodDateUpdate: PropTypes.shape({
    appealId: PropTypes.number,
    changeReason: PropTypes.string,
    closedAt: PropTypes.string,
    newDate: PropTypes.string,
    oldDate: PropTypes.string,
    userFirstName: PropTypes.string,
    userLastName: PropTypes.string
  }),
  timeline: PropTypes.bool
};