import { expect } from 'chai';
import { associateTasksWithAppeals, sortTasks, mapArrayToObjectById } from '../../../app/queue/utils';

describe('QueueTable', () => {
  it('groups tasks by AOD/CAVC and sorts by docket date', () => {
    const serverData = {
      appeals: {
        data: [{
          id: '123',
          attributes: {
            vacols_id: '1',
            aod: true
          }
        }, {
          id: '234',
          attributes: {
            vacols_id: '2',
            type: 'Court Remand'
          }
        }, {
          id: '345',
          attributes: { vacols_id: '3' }
        }]
      },
      tasks: {
        data: [{
          id: '111',
          attributes: {
            appeal_id: '1',
            docket_date: '2017-12-28T17:18:20.412Z'
          }
        }, {
          id: '222',
          attributes: {
            appeal_id: '1',
            docket_date: '2016-10-07T03:15:27.580Z'
          }
        }, {
          id: '333',
          attributes: {
            appeal_id: '2',
            docket_date: '2015-10-13T06:47:34.155Z'
          }
        }, {
          id: '444',
          attributes: {
            appeal_id: '3',
            docket_date: '2016-03-01T04:15:51.123Z'
          }
        }]
      }
    };
    let { tasks, appeals } = associateTasksWithAppeals(serverData);

    tasks = mapArrayToObjectById(tasks);
    appeals = mapArrayToObjectById(appeals, { docCount: 0 });

    const sortedTasks = sortTasks({ tasks, appeals });

    expect(sortedTasks).to.deep.equal([{
      id: '333',
      appealId: '234',
      attributes: {
        appeal_id: '2',
        docket_date: '2015-10-13T06:47:34.155Z'
      }
    }, {
      id: '222',
      appealId: '123',
      attributes: {
        appeal_id: '1',
        docket_date: '2016-10-07T03:15:27.580Z'
      }
    }, {
      id: '111',
      appealId: '123',
      attributes: {
        appeal_id: '1',
        docket_date: '2017-12-28T17:18:20.412Z'
      }
    }, {
      id: '444',
      appealId: '345',
      attributes: {
        appeal_id: '3',
        docket_date: '2016-03-01T04:15:51.123Z'
      }
    }]);
  });
});
