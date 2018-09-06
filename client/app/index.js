import React from 'react';
import ReactOnRails from 'react-on-rails';
import { render } from 'react-dom';
import { AppContainer } from 'react-hot-loader';
import _ from 'lodash';
import './styles/app.scss';
import '../node_modules/pdfjs-dist/web/pdf_viewer.css';

// List of container components we render directly in  Rails .erb files
import BaseContainer from './containers/BaseContainer';
import { Certification } from './certification/Certification';

// Dispatch
import EstablishClaimContainer from './containers/EstablishClaimPage/EstablishClaimContainer';
import ManageEstablishClaim from './manageEstablishClaim/index';
import CaseWorker from './containers/CaseWorker/CaseWorkerIndex';

import Hearings from './hearings/index';
import HearingSchedule from './hearingSchedule/index';
import Help from './help/index';
import Error500 from './errors/Error500';
import Error404 from './errors/Error404';
import Unauthorized from './containers/Unauthorized';
import OutOfService from './containers/OutOfService';
import StatsContainer from './containers/stats/StatsContainer';
import Login from './login';
import TestUsers from './test/TestUsers';
import PerformanceDegradationBanner from './components/PerformanceDegradationBanner';
import EstablishClaimAdmin from './establishClaimAdmin';
import Queue from './queue/index';
import IntakeManager from './intakeManager';
import IntakeEdit from './intakeEdit';

const COMPONENTS = {
  BaseContainer,
  Certification,
  // New SPA wrapper for multiple admin pages
  EstablishClaimAdmin,
  // This is the older admin page that should eventually get merged into
  // the above EstablishClaimAdmin
  ManageEstablishClaim,
  EstablishClaimContainer,
  CaseWorker,
  Login,
  TestUsers,
  Error404,
  Error500,
  OutOfService,
  Unauthorized,
  StatsContainer,
  Hearings,
  HearingSchedule,
  PerformanceDegradationBanner,
  Help,
  Queue,
  IntakeManager,
  IntakeEdit
};

const componentWrapper = (component) => (props, railsContext, domNodeId) => {
  const renderApp = (Component) => {
    const element = (
      <AppContainer>
        <Component {...props} />
      </AppContainer>
    );

    render(element, document.getElementById(domNodeId));
  };

  renderApp(component);

  if (module.hot) {
    module.hot.accept([
      './containers/BaseContainer',
      './containers/EstablishClaimPage/EstablishClaimContainer',
      './login/index',
      './test/TestUsers',
      './containers/stats/StatsContainer',
      './certification/Certification',
      './manageEstablishClaim/ManageEstablishClaim',
      './hearings/index',
      './establishClaimAdmin/index',
      './queue/index',
      './intakeManager/index',
      './intakeEdit/index'
    ], () => renderApp(component));
  }
};

_.forOwn(
  COMPONENTS,
  (component, name) => ReactOnRails.register({ [name]: componentWrapper(component) })
);
