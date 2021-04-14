import React, { useMemo } from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ProgressBar from 'app/components/ProgressBar';
import { useSelector } from 'react-redux';
import { Redirect, Route, Switch, useRouteMatch } from 'react-router';
import { SubstituteAppellantBasicsView } from './basics/SubstituteAppellantBasicsView';
import { SubstituteAppellantPoaView } from './poa/SubstituteAppellantPoaView';
import { SubstituteAppellantTasksView } from './tasks/SubstituteAppellantTasksView';
import { SubstituteAppellantReviewContainer } from './review/SubstituteAppellantReviewContainer';

const sections = [
  '1. Select substitute appellant',
  '2. Select POA',
  '3. Create task',
  '4. Review',
];

export const SubstituteAppellantContainer = () => {
  const { path, url } = useRouteMatch();

  // These can be used to access the appeal or task via other selectors
  // const { appealId, taskId } = useParams();

  const step = useSelector((state) => state.substituteAppellant.step);

  // Keep our progress bar updated based on current step
  const pbSections = useMemo(
    () => sections.map((title, idx) => ({ title, current: idx === step })),
    [step]
  );

  return (
    <AppSegment>
      <ProgressBar sections={pbSections} />
      <Switch>
        <Redirect exact from={[url, `${url}/`]} to={`${url}/basics`} />
        <Route path={`${path}/basics`} title="Substitute Appellant | Caseflow">
          <SubstituteAppellantBasicsView />
        </Route>

        <Route path={`${path}/poa`} title="Substitute Appellant | Caseflow">
          <SubstituteAppellantPoaView />
        </Route>

        <Route path={`${path}/tasks`} title="Substitute Appellant | Caseflow">
          <SubstituteAppellantTasksView />
        </Route>

        <Route path={`${path}/review`} title="Substitute Appellant | Caseflow">
          <SubstituteAppellantReviewContainer />
        </Route>
      </Switch>
    </AppSegment>
  );
};
