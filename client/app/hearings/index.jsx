import React from 'react';
import ReduxBase from 'appeals-frontend-toolkit/components/ReduxBase';

import { BrowserRouter, Route, Switch } from 'react-router-dom';
import DocketsContainer from './containers/DocketsContainer';
import DailyDocketContainer from './containers/DailyDocketContainer';
import HearingWorksheetContainer from './containers//HearingWorksheetContainer';
import { hearingsReducers, mapDataToInitialState } from './reducers/index';
import ScrollToTop from './util/ScrollTop';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';

const Hearings = ({ hearings }) => {

  return <ReduxBase reducer={hearingsReducers} initialState={mapDataToInitialState(hearings)}>
    <BrowserRouter>
      <Switch>
        <PageRoute exact path="/hearings/:hearingId/worksheet/print"
          breadcrumb="Daily Docket > Hearing Worksheet"
          title="Hearing Worksheet"
          component={(props) => (
            <HearingWorksheetContainer
              print
              veteran_law_judge={hearings.veteran_law_judge}
              hearingId={props.match.params.hearingId} />
          )}
        />
        <Route>
          <div>
            <NavigationBar
              appName="Hearing Prep"
              defaultUrl="/hearings/dockets"
              userDisplayName={hearings.userDisplayName}
              dropdownUrls={hearings.dropdownUrls}>
              <AppFrame>
                <ScrollToTop />
                <PageRoute exact path="/hearings/dockets"
                  title="Your Hearing Days"
                  component={() => <DocketsContainer veteranLawJudge={hearings.veteran_law_judge} />} />

                <PageRoute exact path="/hearings/dockets/:date"
                  breadcrumb="Daily Docket"
                  title="Daily Docket"
                  component={(props) => (
                    <DailyDocketContainer
                      veteran_law_judge={hearings.veteran_law_judge}
                      date={props.match.params.date} />
                  )}
                />

                <PageRoute exact path="/hearings/:hearingId/worksheet"
                  breadcrumb="Daily Docket > Hearing Worksheet"
                  title="Hearing Worksheet"
                  component={(props) => (
                    <HearingWorksheetContainer
                      veteran_law_judge={hearings.veteran_law_judge}
                      hearingId={props.match.params.hearingId} />
                  )}
                />

              </AppFrame>
            </NavigationBar>
            <Footer
              appName="Hearing Prep"
              feedbackUrl={hearings.feedbackUrl}
              buildDate={hearings.buildDate} />
          </div>
        </Route>
      </Switch>
    </BrowserRouter>
  </ReduxBase>;
};

export default Hearings;
