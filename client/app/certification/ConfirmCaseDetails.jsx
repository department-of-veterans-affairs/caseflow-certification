import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as actions from './actions/ConfirmCaseDetails';
import * as certificationActions from './actions/Certification';
import { Redirect } from 'react-router-dom';

import ValidatorsUtil from '../util/ValidatorsUtil';
import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import Table from '../components/Table';
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

const poaMatchesOptions = [
  { displayText: 'Yes',
    value: Constants.poaMatches.MATCH },
  { displayText: 'No',
    value: Constants.poaMatches.NO_MATCH }
];

const poaCorrectInVacolsOptions = [
  { displayText: 'VBMS',
    value: Constants.poaCorrectInVacols.VBMS },
  { displayText: 'VACOLS',
    value: Constants.poaCorrectInVacols.VACOLS },
  { displayText: 'None of the above',
    value: Constants.poaCorrectInVacols.NONE }
];

// TODO: We should give each question a constant name.
const ERRORS = {
  representativeType: 'Please enter the representative type.',
  representativeName: 'Please enter the representative name.',
  otherRepresentativeType: 'Please enter the other representative type.',
  poaMatches: 'Please select yes or no.',
  poaCorrectInVacols: 'Please select an option'
};

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
      otherRepresentativeType,
      poaMatches,
      poaCorrectInVacols
    } = this.props;

    const erroredFields = [];

    if (ValidatorsUtil.requiredValidator(poaMatches)) {
      erroredFields.push('poaMatches');
    }

    if (poaMatches === 'NO_MATCH' && ValidatorsUtil.requiredValidator(poaCorrectInVacols)) {
      erroredFields.push('poaCorrectInVacols');
    }

    // We always need a representative type.
    if (ValidatorsUtil.requiredValidator(representativeType)) {
      erroredFields.push('representativeType');
    }

    // Unless the type of representative is "None",
    // we need a representative name.
    if (ValidatorsUtil.requiredValidator(representativeName) && !this.representativeTypeIsNone()) {
      erroredFields.push('representativeName');
    }

    // If the representative type is "Other",
    // fill out the representative type.
    if (this.representativeTypeIsOther() && ValidatorsUtil.requiredValidator(otherRepresentativeType)) {
      erroredFields.push('otherRepresentativeType');
    }

    return erroredFields;
  }

  onClickContinue() {

    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.showValidationErrors(erroredFields);

      return;
    }

    this.props.certificationUpdateStart({
      representativeType: this.props.representativeType,
      otherRepresentativeType: this.props.otherRepresentativeType,
      representativeName: this.props.representativeName,
      poaMatches: this.props.poaMatches,
      poaCorrectInVacols: this.props.poaCorrectInVacols,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  isFieldErrored(fieldName) {
    return this.props.erroredFields && this.props.erroredFields.includes(fieldName);
  }

  componentDidUpdate () {
    if (this.props.scrollToError && this.props.erroredFields) {
      ValidatorsUtil.scrollToAndFocusFirstError();
      // This sets scrollToError to false so that users can edit other fields
      // without being redirected back to the first errored field.
      this.props.showValidationErrors(this.props.erroredFields, false);
    }
  }

  render() {
    let {
      representativeType,
      changeRepresentativeType,
      poaMatches,
      changePoaMatches,
      poaCorrectInVacols,
      changePoaCorrectInVacols,
      bgsRepresentativeType,
      bgsRepresentativeName,
      vacolsRepresentativeType,
      vacolsRepresentativeName,
      representativeName,
      changeRepresentativeName,
      otherRepresentativeType,
      changeOtherRepresentativeType,
      loading,
      serverError,
      updateSucceeded,
      match
    } = this.props;

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`}/>;
    }

    if (serverError) {
      return <Redirect
        to={'/certifications/error'}/>;
    }

    const shouldShowOtherTypeField =
      representativeType === Constants.representativeTypes.OTHER;

    let appellantInfoColumns = [
      {
        header: <h3>From VBMS</h3>,
        valueName: 'vbms'
      },
      {
        header: <h3>From VACOLS</h3>,
        valueName: 'vacols'
      }
    ];

    let appellantInfoRowObjects = [
      {
        vbms: bgsRepresentativeName,
        vacols: vacolsRepresentativeName
      },
      {
        vbms: bgsRepresentativeType,
        vacols: vacolsRepresentativeType
      }
    ];

    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Confirm Case Details</h2>

          <div>
            {`Review information about the appellant's
              representative from VBMS and VACOLS.`}
          </div>

          <Table
            className="cf-borderless-rows"
            columns={appellantInfoColumns}
            rowObjects={appellantInfoRowObjects}
            summary="Appellant Information"
          />

          <div className="cf-help-divider"></div>

          <RadioField
            name="Does the representative information from VBMS and VACOLS match?"
            required={true}
            options={poaMatchesOptions}
            value={poaMatches}
            errorMessage={this.isFieldErrored('poaMatches') ? ERRORS.poaMatches : null}
            onChange={changePoaMatches}
          />

          {
            poaMatches === 'NO_MATCH' &&
            <RadioField
              name="Which information source shows the correct representative for this appeal?"
              options={poaCorrectInVacolsOptions}
              value={poaCorrectInVacols}
              onChange={changePoaCorrectInVacols}
              errorMessage={this.isFieldErrored('poaCorrectInVacols') ? ERRORS.poaCorrectInVacols : null}
              required={true}
            />

          }

          <RadioField
            name="Representative type"
            options={representativeTypeOptions}
            value={representativeType}
            onChange={changeRepresentativeType}
            errorMessage={this.isFieldErrored('representativeType') ? ERRORS.representativeType : null}
            required={true}
          />

          {
            shouldShowOtherTypeField &&
            <TextField
              name={'Specify other representative type'}
              value={otherRepresentativeType}
              onChange={changeOtherRepresentativeType}
              errorMessage={this.isFieldErrored('otherRepresentativeType') ? ERRORS.otherRepresentativeType : null}
              required={true}
            />
          }

          <TextField
            name={'Representative name'}
            value={representativeName}
            onChange={changeRepresentativeName}
            errorMessage={this.isFieldErrored('representativeName') ? ERRORS.representativeName : null}
            required={true}
          />

        </div>

        <Footer
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
  poaMatches: PropTypes.string,
  poaCorrectInVacols: PropTypes.string,
  changePoaMatches: PropTypes.func,
  changePoaCorrectInVacols: PropTypes.func,
  otherRepresentativeType: PropTypes.string,
  changeOtherRepresentativeType: PropTypes.func,
  erroredFields: PropTypes.array,
  scrollToError: PropTypes.bool,
  match: PropTypes.object.isRequired
};

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch(actions.updateProgressBar());
  },

  showValidationErrors: (erroredFields, scrollToError = true) => {
    dispatch(certificationActions.showValidationErrors(erroredFields, scrollToError));
  },

  resetState: () => dispatch(certificationActions.resetState()),

  changeRepresentativeName: (name) => dispatch(actions.changeRepresentativeName(name)),

  changeRepresentativeType: (type) => dispatch(actions.changeRepresentativeType(type)),

  changeOtherRepresentativeType: (other) => {
    dispatch(actions.changeOtherRepresentativeType(other));
  },

  changePoaMatches: (poaMatches) => dispatch(actions.changePoaMatches(poaMatches)),
  changePoaCorrectInVacols: (poaCorrectInVacols) => dispatch(actions.changePoaCorrectInVacols(poaCorrectInVacols)),

  certificationUpdateStart: (props) => {
    dispatch(actions.certificationUpdateStart(props, dispatch));
  }
});

const mapStateToProps = (state) => ({
  updateSucceeded: state.updateSucceeded,
  serverError: state.serverError,
  representativeType: state.representativeType,
  representativeName: state.representativeName,
  bgsRepresentativeType: state.bgsRepresentativeType,
  bgsRepresentativeName: state.bgsRepresentativeName,
  vacolsRepresentativeType: state.vacolsRepresentativeType,
  vacolsRepresentativeName: state.vacolsRepresentativeName,
  otherRepresentativeType: state.otherRepresentativeType,
  poaMatches: state.poaMatches,
  poaCorrectInVacols: state.poaCorrectInVacols,
  continueClicked: state.continueClicked,
  erroredFields: state.erroredFields,
  scrollToError: state.scrollToError,
  loading: state.loading
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ConfirmCaseDetails);
