import { leftPad } from './StringUtil';

const ZERO_INDEX_MONTH_OFFSET = 1;
const MILLISECONDS_IN_A_DAY = 86400000;

export const formatDate = function(dateString) {
  let date = new Date(dateString);
  let month = leftPad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  let day = leftPad(date.getDate(), 2, '0');
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};

export const addDays = function(date, days) {
  let dateString = date.getTime() + days * MILLISECONDS_IN_A_DAY;
  return new Date(dateString)
};
