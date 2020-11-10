export const DISPOSITIONS = {
  granted: {
    displayText: 'Grant all issues',
    judgeRulingText: 'full switch',
    value: 'granted',
    dispositionType: 'Granted'
  },
  partially_granted: {
    displayText: 'Grant a partial switch',
    judgeRulingText: 'partial switch',
    value: 'partially_granted',
    help: 'e.g. if the Board is only granting a few issues',
    dispositionType: 'Granted',
  },
  denied: {
    displayText: 'Deny all issues',
    judgeRulingText: 'denial',
    value: 'denied',
    dispositionType: 'Denied'
  },
};
