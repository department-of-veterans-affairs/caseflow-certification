import React from 'react';

import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import { mount } from 'enzyme';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import TIMEZONES from 'constants/TIMEZONES';

const [timezoneLabel] = Object.keys(TIMEZONES).filter((zone) => TIMEZONES[zone] === COMMON_TIMEZONES[3]);

describe('HearingTime', () => {
  // Ignore warnings about SearchableDropdown
  jest.spyOn(console, 'error').mockReturnValue();

  test('Matches snapshot with default props when passed in', () => {
    const form = mount(
      <HearingTime />
    );

    expect(form).toMatchSnapshot();

    const checkedRadio = form.find('input').find({ checked: true });

    // A single input is checked by default, and it's the "Other" radio
    expect(checkedRadio.exists()).toBe(true);
    expect(checkedRadio.exists({ value: 'other' })).toBe(true);

    const dropdown = form.find('Select');

    // The select field is not disabled by default (meaning the "Other")
    // radio is checked
    expect(dropdown.exists());
    expect(dropdown.exists({ disabled: false })).toBe(true);

    // Expect the naming of forms to match expected
    expect(form.exists({ name: 'hearingTime0' })).toBe(true);
    expect(form.exists({ name: 'optionalHearingTime0' })).toBe(true);
  });
  test('Matches snapshot when enableZone is true', () => {
    // Run the test
    const hearingTime = mount(<HearingTime enableZone value={HEARING_TIME_OPTIONS[0].value} />);

    // Assertions
    expect(hearingTime).toMatchSnapshot();
    expect(hearingTime.findWhere((node) => node.props().className === 'Select-value-label').text()).toContain(timezoneLabel);
  });

  test('Matches snapshot when other time is not selected', () => {
    const form = mount(
      <HearingTime
        value="12:30"
      />
    );

    expect(form).toMatchSnapshot();

    expect(form.exists('SearchableDropdown')).toBe(false);
    expect(
      form.find('input').exists({ checked: true, value: '12:30' })
    ).toBe(true);
  });

  test('Matches snapshot when other time is selected', () => {
    const form = mount(
      <HearingTime
        value="13:45"
      />
    );

    expect(form).toMatchSnapshot();

    // Expect "Other" radio to be checked
    expect(
      form.find('input').exists({ checked: true, value: 'other' })
    ).toBe(true);

    // Expect dropdown to be populated with correct time
    expect(form.exists('SearchableDropdown')).toBe(true);
    expect(
      form.find('Select').exists({ value: '13:45' })
    ).toBe(true);
  });

  test('Matches snapshot when readonly prop is set', () => {
    const form = mount(
      <HearingTime />
    );

    expect(form).toMatchSnapshot();

    expect(form.find('select').every({ disabled: true })).toBe(true);
  });
});
