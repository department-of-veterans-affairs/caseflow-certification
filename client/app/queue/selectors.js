// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  LegacyTask,
  LegacyTasks,
  Appeal,
  Appeals,
  AmaTask,
  AmaTasks,
  BasicAppeals,
  User
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => {
  return _.flatMap(
    state.queue.isTaskAssignedToUserSelected[userId] || {},
    (selected, id) => selected ? [state.queue.tasks[id]] : []
  );
};

const getTasks = (state: State) => state.queue.tasks;
const getAmaTasks = (state: State) => state.queue.amaTasks;
const getAppeals = (state: State) => state.queue.appeals;
const getAppealDetails = (state: State) => state.queue.appealDetails;
const getUserCssId = (state: State) => state.ui.userCssId;
const getAppealId = (state: State, props: Object) => props.appealId;
const getAttorneys = (state: State) => state.queue.attorneysOfJudge;
const getCaseflowVeteranId = (state: State, props: Object) => props.caseflowVeteranId;

export const appealsWithTasksSelector = createSelector(
  [getTasks, getAmaTasks, getAppeals],
  (tasks: LegacyTasks, amaTasks: AmaTasks, appeals: Appeals) => {
    return _.map(appeals, (appeal) => {
      return { ...appeal,
        tasks: [
          ..._.filter(tasks, (task) => task.externalAppealId === appeal.externalId),
          ..._.filter(amaTasks, (amaTask) => amaTask.externalAppealId === appeal.externalId)
        ]
      };
    });
  }
);

export const tasksWithAppealSelector = createSelector(
  [getTasks, getAmaTasks, getAppeals],
  (tasks: LegacyTasks, amaTasks: AmaTasks, appeals: Appeals) => {
    return [
      ..._.map(tasks, (task) => {
        return { ...task,
          appeal: _.find(appeals, (appeal) => task.externalAppealId === appeal.externalId)
        };
      }),
      ..._.map(amaTasks, (amaTask) => {
        return { ...amaTask,
          appeal: _.find(appeals, (appeal) => amaTask.externalAppealId === appeal.externalId)
        };
      })
    ];
  }
);

export const appealsWithDetailsSelector = createSelector(
  [getAppeals, getAppealDetails],
  (appeals: BasicAppeals, appealDetails: Appeals) => {
    return _.merge(appeals, appealDetails);
  }
);

export const appealWithDetailSelector = createSelector(
  [appealsWithDetailsSelector, getAppealId],
  (appeals: Appeals, appealId: string) => appeals[appealId]
);

export const getTasksForAppeal = createSelector(
  [getTasks, getAppealId],
  (tasks: LegacyTasks, appealId: number) => {
    return _.filter(tasks, (task) => task.externalAppealId === appealId);
  }
);

export const tasksForAppealAssignedToUserSelector = createSelector(
  [getTasksForAppeal, getUserCssId],
  (tasks: LegacyTasks, cssId: string) => {
    return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
  }
);

export const tasksForAppealAssignedToAttorneySelector = createSelector(
  [getTasksForAppeal, getAttorneys],
  (tasks: LegacyTasks, attorneys: Array<User>) => {
    return _.filter(tasks, (task) => _.some(attorneys, (attorney) => task.assignedTo.cssId === attorney.css_id));
  }
);

export const appealsByCaseflowVeteranId = createSelector(
  [appealsWithDetailsSelector, getCaseflowVeteranId],
  (appeals: Appeals, caseflowVeteranId: string) =>
    _.filter(appeals, (appeal: Appeal) => appeal.caseflowVeteranId &&
      appeal.caseflowVeteranId.toString() === caseflowVeteranId.toString())
);

export const tasksByAssigneeCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks: Array<AmaTask | LegacyTask>, cssId: string) =>
    _.filter(tasks, (task) => task.assignedTo.cssId === cssId)
);

export const newTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks: Array<AmaTask | LegacyTask>) => tasks.filter((task) => !task.placedOnHoldAt)
);


export const judgeReviewTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) =>
    _.filter(tasks, (task: AmaTask | LegacyTask) => task.taskType === 'Review' || task.taskType === null)
);

export const judgeAssignTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) => _.filter(tasks, (task) => task.taskType === 'Assign')
);

// ***************** Non-memoized selectors *****************

const getAttorney = (state: State, attorneyId: string) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return _.find(state.queue.attorneysOfJudge, (attorney: User) => attorney.id.toString() === attorneyId);
};

export const getAssignedTasks = (state: State, attorneyId: string) => {
  const tasks = tasksWithAppealSelector(state);
  const attorney = getAttorney(state, attorneyId);
  const cssId = attorney ? attorney.css_id : null;

  return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
};

export const getTasksByUserId = (state: State) => {
  const tasks = tasksWithAppealSelector(state);
  const attorneys = state.queue.attorneysOfJudge;
  const attorneysByCssId = _.keyBy(attorneys, 'css_id');

  return _.reduce(tasks, (appealsByUserId: Object, task: Appeal) => {
    const appealCssId = task.assignedTo.cssId;
    const attorney = attorneysByCssId[appealCssId];

    if (!attorney) {
      return appealsByUserId;
    }

    appealsByUserId[attorney.id] = [...(appealsByUserId[attorney.id] || []), task];

    return appealsByUserId;
  }, {});
};
