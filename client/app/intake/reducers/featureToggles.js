import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    correctClaimReviews: {
      $set: Boolean(featureToggles.correctClaimReviews)
    },
    covidTimelinessExemption: {
      $set: Boolean(featureToggles.covidTimelinessExemption)
    },
    verifyUnidentifiedIssue: {
      $set: Boolean(featureToggles.verifyUnidentifiedIssue)
    },
    attorneyFees: {
      $set: Boolean(featureToggles.attorneyFees)
    },
    nonVeteranClaimants: {
      $set: Boolean(featureToggles.nonVeteranClaimants)
    },
    deceasedAppellants: {
      $set: Boolean(featureToggles.deceasedAppellants)
    },
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      correctClaimReviews: false,
      verifyUnidentifiedIssue: false,
      establishFiduciaryEps: false,
      editEpClaimLabels: false,
      deceasedAppellants: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
