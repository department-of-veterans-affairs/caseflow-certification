import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment';

import Tooltip from '../../../components/Tooltip';
import Button from '../../../components/Button';
import {
  buttonSelectedStyle,
  buttonUnselectedStyle,
  dateStyle,
  leftColumnStyle,
  rightColumnStyle,
  typeAndJudgeStyle,
  slotDisplayStyle,
  scheduledDisplayStyle
} from './styles';

import {
  formatHearingType,
  vljFullnameOrEmptyString,
  formatSlotRatio,
  hearingDayHasJudge,
  separatorIfJudgeOrRoomPresent,
  hearingRoomOrEmptyString
} from '../../utils';

export const HearingDayInfoButton = ({ id, hearingDay, selected, onSelectedHearingDayChange }) => {
  // Format the pieces of information from hearingDay
  const formattedHearingType = formatHearingType(hearingDay.readableRequestType);
  const judgeOrRoom = hearingDayHasJudge(hearingDay) ?
    vljFullnameOrEmptyString(hearingDay) :
    hearingRoomOrEmptyString(hearingDay);
  const separator = separatorIfJudgeOrRoomPresent(hearingDay);
  const formattedSlotRatio = formatSlotRatio(hearingDay);
  const formattedDate = moment(hearingDay.scheduledFor).format('ddd MMM D');

  const classNames = selected ? ['selected-hearing-day-info-button'] : ['unselected-hearing-day-info-button'];

  return (
    <Button
      styling={selected ? buttonSelectedStyle : buttonUnselectedStyle}
      onClick={() => onSelectedHearingDayChange(hearingDay)}
      classNames={classNames}
      linkStyling
    >
      <div>
        <div {...leftColumnStyle} >
          <div {...dateStyle}>
            {formattedDate}
          </div>
          <div {...typeAndJudgeStyle}>
            <Tooltip id={`hearing-day-${id}`} text={judgeOrRoom} position="bottom" tabIndex={-1}>
              {`${formattedHearingType} ${separator} ${judgeOrRoom}`}
            </Tooltip>
          </div>
        </div>
        <div {...rightColumnStyle} >
          <div {...slotDisplayStyle}>
            {formattedSlotRatio}
          </div>
          <div {...scheduledDisplayStyle}>scheduled</div>
        </div>
      </div>
    </Button>
  );
};

HearingDayInfoButton.propTypes = {
  id: PropTypes.number,
  hearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  selected: PropTypes.bool,
  onSelectedHearingDayChange: PropTypes.func,
};

export default HearingDayInfoButton;
