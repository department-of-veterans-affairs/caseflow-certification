import { expect } from 'chai';
import * as Constants from '../../../app/manageEstablishClaim/constants';
import manageEstablishClaimReducer, { getManageEstablishClaimInitialState } from
  '../../../app/manageEstablishClaim/reducers/index';

 /* eslint-disable no-unused-expressions */
describe('getManageEstablishClaimInitialState', () => {
  let state;

  beforeEach(() => {
    state = getManageEstablishClaimInitialState({
      userQuotas: [
        {
          user_name: null,
          task_count: 5,
          tasks_completed_count: 0,
          tasks_left_count: 5
        }
      ]
    });
  });

  it('updates quotas and employeeCount', () => {
    expect(state.userQuotas[0].userName).to.equal('1. Not logged in');
    expect(state.userQuotas[0].taskCount).to.equal(5);
    expect(state.userQuotas[0].tasksCompletedCount).to.equal(0);
    expect(state.userQuotas[0].tasksLeftCount).to.equal(5);
    expect(state.userQuotas[0].isAssigned).to.equal(false);

    expect(state.employeeCount).to.eql(1);
  });
});

describe('manageEstablishClaimReducer', () => {
  let initialState;

  beforeEach(() => {
    initialState = getManageEstablishClaimInitialState({
      userQuotas: [
        {
          user_name: 'Steph Curry',
          task_count: 5,
          tasks_completed_count: 0,
          tasks_left_count: 5
        },
        {
          user_name: 'Klay Thompson',
          task_count: 7,
          tasks_completed_count: 3,
          tasks_left_count: 4
        },
        {
          user_name: 'Draymond Green',
          task_count: 7,
          tasks_completed_count: 3,
          tasks_left_count: 4
        }
      ]
    });
  });

  context(Constants.CHANGE_EMPLOYEE_COUNT, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.CHANGE_EMPLOYEE_COUNT,
        payload: { employeeCount: 7 }
      });
    });

    it('updates value', () => {
      expect(state.employeeCount).to.eq(7);
    });
  });

  context(Constants.CLEAR_ALERT, () => {
    let state;

    beforeEach(() => {
      initialState.alert = 'ALERT!';
      state = manageEstablishClaimReducer(initialState, { type: Constants.CLEAR_ALERT });
    });

    it('updates value', () => {
      expect(state.alert).to.eql(null);
    });
  });

  context(Constants.REQUEST_USER_QUOTAS_SUCCESS, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.REQUEST_USER_QUOTAS_SUCCESS,
        payload: { userQuotas: [
          {
            id: 'DRAY',
            user_name: 'Draymond Green',
            task_count: 7,
            tasks_completed_count: 3,
            tasks_left_count: 4,
            'locked?': true
          },
          {
            id: null,
            user_name: null,
            task_count: 7,
            tasks_completed_count: 0,
            tasks_left_count: 7
          }
        ] }
      });
    });

    it('updates quotas and employeeCount', () => {
      expect(state.userQuotas[0]).to.eql({
        id: 'DRAY',
        index: 0,
        userName: '1. Draymond Green',
        taskCount: 7,
        tasksCompletedCount: 3,
        isEditingTaskCount: false,
        tasksLeftCount: 4,
        isAssigned: true,
        isLocked: true
      });

      expect(state.userQuotas[1]).to.eql({
        id: null,
        index: 1,
        userName: '2. Not logged in',
        taskCount: 7,
        isEditingTaskCount: false,
        tasksCompletedCount: 0,
        tasksLeftCount: 7,
        isAssigned: false,
        isLocked: false
      });

      expect(state.employeeCount).to.eql(2);
    });
  });

  context(Constants.BEGIN_EDIT_TASK_COUNT, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.BEGIN_EDIT_TASK_COUNT,
        payload: { userQuotaIndex: 2 }
      });
    });

    it('sets taskCountEdit on userQuota', () => {
      expect(state.userQuotas[0].isEditingTaskCount).to.eql(false);
      expect(state.userQuotas[0].newTaskCount).to.not.exist;
      expect(state.userQuotas[1].isEditingTaskCount).to.eql(false);
      expect(state.userQuotas[1].newTaskCount).to.not.exist;
      expect(state.userQuotas[2].isEditingTaskCount).to.eql(true);
      expect(state.userQuotas[2].newTaskCount).to.eql(7);
    });
  });

  context(Constants.CHANGE_NEW_TASK_COUNT, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.CHANGE_NEW_TASK_COUNT,
        payload: { userQuotaIndex: 1,
          taskCount: 40 }
      });
    });

    it('sets taskCountEdit on userQuota', () => {
      expect(state.userQuotas[0].newTaskCount).to.not.exist;
      expect(state.userQuotas[1].newTaskCount).to.eql(40);
      expect(state.userQuotas[2].newTaskCount).to.not.exist;
    });

  });
});
/* eslint-enable no-unused-expressions */
