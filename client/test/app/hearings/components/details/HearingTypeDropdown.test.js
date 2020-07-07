import React from 'react';
import { shallow, mount } from 'enzyme';

import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING, HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import { virtualHearing } from 'test/data/hearings';
import Select from 'react-select';

// Set the default options
const centralOpts = [
  {
    label: CENTRAL_OFFICE_HEARING,
    value: false
  },
  {
    label: 'Virtual',
    value: true
  }
];

const videoOpts = [
  {
    label: VIDEO_HEARING,
    value: false
  },
  centralOpts[1]
];

// Create the method spies
const updateSpy = jest.fn();
const openModalSpy = jest.fn();
const convertHearingSpy = jest.fn();

describe('HearingTypeDropdown', () => {
  test('Matches snapshot with default props for central office hearings', () => {
    // Render the address component
    const hearingType = shallow(
      <HearingTypeDropdown
        requestType={CENTRAL_OFFICE_HEARING}
      />
    );

    // Assertions
    expect(hearingType).toMatchSnapshot();
    expect(hearingType.find(SearchableDropdown)).toHaveLength(1);
    expect(hearingType.prop('label')).toEqual('Hearing Type');
    expect(hearingType.prop('options')).toEqual(centralOpts);
    expect(hearingType.prop('value')).toEqual(centralOpts[0]);
  });

  test('Matches snapshot with default props for video hearings', () => {
    // Render the address component
    const hearingType = shallow(
      <HearingTypeDropdown
        requestType={VIDEO_HEARING}
      />
    );

    // Assertions
    expect(hearingType).toMatchSnapshot();
    expect(hearingType.find(SearchableDropdown)).toHaveLength(1);
    expect(hearingType.prop('label')).toEqual('Hearing Type');
    expect(hearingType.prop('options')).toEqual(videoOpts);
    expect(hearingType.prop('value')).toEqual(videoOpts[0]);
  });

  test('Matches snapshot with default props for virtual hearings', () => {
    // Render the address component
    const hearingType = shallow(
      <HearingTypeDropdown
        requestType={CENTRAL_OFFICE_HEARING}
        virtualHearing={virtualHearing.virtualHearing}
      />
    );

    // Assertions
    expect(hearingType).toMatchSnapshot();
    expect(hearingType.find(SearchableDropdown)).toHaveLength(1);
    expect(hearingType.prop('label')).toEqual('Hearing Type');
    expect(hearingType.prop('options')).toEqual(centralOpts);
    expect(hearingType.prop('value')).toEqual(centralOpts[1]);
  });

  test('Can change from central office hearing', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        requestType={CENTRAL_OFFICE_HEARING}
        convertHearing={convertHearingSpy}
        update={updateSpy}
      />
    );

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[0]);

    // Change the hearing
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 40 });
    hearingType.find('input').simulate('change', { target: { value: centralOpts[1].label } });
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[1]);
    expect(convertHearingSpy).toHaveBeenCalledWith(HEARING_CONVERSION_TYPES[0]);
    expect(updateSpy).toHaveBeenCalledWith('virtualHearing', { requestCancelled: false, jobCompleted: false });
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from video hearing', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        requestType={VIDEO_HEARING}
        openModal={openModalSpy}
        update={updateSpy}
      />
    );

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[0]);

    // Change the hearing
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 40 });
    hearingType.find('input').simulate('change', { target: { value: videoOpts[1].label } });
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[1]);
    expect(openModalSpy).toHaveBeenCalledWith({ type: HEARING_CONVERSION_TYPES[0] });
    expect(updateSpy).toHaveBeenCalledWith('virtualHearing', { requestCancelled: false, jobCompleted: false });
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from virtual hearing to central', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        requestType={CENTRAL_OFFICE_HEARING}
        virtualHearing={virtualHearing.virtualHearing}
        convertHearing={convertHearingSpy}
        update={updateSpy}
      />
    );

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[1]);

    // Change the hearing
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 40 });
    hearingType.find('input').simulate('change', { target: { value: centralOpts[0].label } });
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(centralOpts[0]);
    expect(convertHearingSpy).toHaveBeenCalledWith(HEARING_CONVERSION_TYPES[1]);
    expect(updateSpy).toHaveBeenCalledWith('virtualHearing', { requestCancelled: true, jobCompleted: false });
    expect(hearingType).toMatchSnapshot();
  });

  test('Can change from virtual hearing to video', () => {
    // Render the address component
    const hearingType = mount(
      <HearingTypeDropdown
        requestType={VIDEO_HEARING}
        virtualHearing={virtualHearing.virtualHearing}
        openModal={openModalSpy}
        update={updateSpy}
      />
    );

    // Initial state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[1]);

    // Change the hearing
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 40 });
    hearingType.find('input').simulate('change', { target: { value: videoOpts[0].label } });
    hearingType.find(SearchableDropdown).find('.Select-control').
      simulate('keyDown', { keyCode: 13 });

    // New state
    expect(hearingType.find(Select).prop('value')).toEqual(videoOpts[0]);
    expect(openModalSpy).toHaveBeenCalledWith({ type: HEARING_CONVERSION_TYPES[1] });
    expect(updateSpy).toHaveBeenCalledWith('virtualHearing', { requestCancelled: true, jobCompleted: false });
    expect(hearingType).toMatchSnapshot();
  });
})
;
