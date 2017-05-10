import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as actions from './actions/ConfirmCaseDetails';
import * as certificationActions from './actions/Certification';
import { Redirect } from 'react-router-dom';

import requiredValidator from '../util/validators/RequiredValidator';
import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import Footer from './Footer';

const representativeTypeOptions = [
  {
    displayText: 'Attorney',
    value: Constants.representativeTypes.ATTORNEY
  },
  {
    displayText: 'Agent',
    value: Constants.representativeTypes.AGENT
  },
  {
    displayText: 'Organization',
    value: Constants.representativeTypes.ORGANIZATION
  },
  {
    displayText: 'None',
    value: Constants.representativeTypes.NONE
  },
  {
    displayText: 'Other',
    value: Constants.representativeTypes.OTHER
  }
];

/*
 * Confirm Case Details
 *
 * This page will display information from BGS
 * about the appellant's representation for the appeal
 * and confirm it.
 *
 * On the backend, we'll then update that information in VACOLS
 * if necessary. This was created since power of attorney
 * information in VACOLS is very often out of date, which can
 * in case delays -- attorneys can't access the appeal information
 * if they're not noted as being the appellant's representative
 *
 */

export class ConfirmCaseDetails extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  componentWillUnmount() {
    this.props.resetState();
  }

  representativeTypeIsNone() {
    return this.props.representativeType === Constants.representativeTypes.NONE;
  }

  representativeTypeIsOther() {
    return this.props.representativeType === Constants.representativeTypes.OTHER;
  }

  getValidationErrors() {
    // TODO: consider breaking this and all validation out into separate
    // modules.
    let {
      representativeName,
      representativeType,
      otherRepresentativeType
    } = this.props;

    const erroredFields = [];

    // Unless the type of representative is "None",
    // we need a representative name.
    if (requiredValidator('Please enter a representative name.')(representativeName) && !this.representativeTypeIsNone()) {
      erroredFields.push('Representative name');
    }

    // We always need a representative type.
    if (requiredValidator('Please enter a representative type.')(representativeType)) {
      erroredFields.push('Representative type');
    }

    // If the representative type is "Other",
    // fill out the representative type.
    if (this.representativeTypeIsOther() && requiredValidator('Please enter the representative type.')(otherRepresentativeType)) {
      erroredFields.push('Specify other representative type');
    }

    return erroredFields;
  }

  onClickContinue() {

    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      window.scrollBy(0, document.getElementById(erroredFields[0]).getBoundingClientRect().top - 30);

      return;
    }

    this.props.certificationUpdateStart({
      representativeType: this.props.representativeType,
      otherRepresentativeType: this.props.otherRepresentativeType,
      representativeName: this.props.representativeName,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  render() {
    let {
      representativeType,
      changeRepresentativeType,
      representativeName,
      changeRepresentativeName,
      otherRepresentativeType,
      changeOtherRepresentativeType,
      loading,
      updateFailed,
      updateSucceeded,
      match
    } = this.props;

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`}/>;
    }

    if (updateFailed) {
      // TODO: add real error handling and validated error states etc.
      return <div>500 500 error error</div>;
    }

    const shouldShowOtherTypeField =
      representativeType === Constants.representativeTypes.OTHER;

    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Confirm Case Details</h2>

          <div>
            {`Review data from BGS about the appellant's
              representative and make changes if necessary.`}
          </div>

          <RadioField name="Representative type"
            options={representativeTypeOptions}
            value={representativeType}
            onChange={changeRepresentativeType}
            required={true}/>

          {
            shouldShowOtherTypeField &&
            <TextField
              name="Specify other representative type"
              value={otherRepresentativeType}
              onChange={changeOtherRepresentativeType}
              required={true}/>
          }

          <TextField name="Representative name"
            value={representativeName}
            onChange={changeRepresentativeName}
            required={true}/>

        </div>

        <Footer
          disableContinue={false}
          loading={loading}
          onClickContinue={this.onClickContinue.bind(this)}
        />
    </div>;
  }
}

ConfirmCaseDetails.propTypes = {
  representativeType: PropTypes.string,
  changeRepresentativeType: PropTypes.func,
  representativeName: PropTypes.string,
  changeRepresentativeName: PropTypes.func,
  otherRepresentativeType: PropTypes.string,
  changeOtherRepresentativeType: PropTypes.func,
  match: PropTypes.object.isRequired
};

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch(actions.updateProgressBar());
  },

  resetState: () => dispatch(certificationActions.resetState()),

  changeRepresentativeName: (name) => dispatch(actions.changeRepresentativeName(name)),

  changeRepresentativeType: (type) => dispatch(actions.changeRepresentativeType(type)),

  changeOtherRepresentativeType: (other) => {
    dispatch(actions.changeOtherRepresentativeType(other));
  },

  certificationUpdateStart: (props) => {
    dispatch(actions.certificationUpdateStart(props, dispatch));
  }
});

const mapStateToProps = (state) => ({
  updateSucceeded: state.updateSucceeded,
  updateFailed: state.updateFailed,
  representativeType: state.representativeType,
  representativeName: state.representativeName,
  otherRepresentativeType: state.otherRepresentativeType,
  loading: state.loading,
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ConfirmCaseDetails);
