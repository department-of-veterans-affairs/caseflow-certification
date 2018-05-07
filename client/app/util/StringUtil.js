import _ from 'lodash';

const StringUtil = {

  camelCaseToDashCase(variable) {
    // convert key from camelCase to dash-case
    return variable.replace(/([A-Z])/g, ($1) => `-${$1.toLowerCase()}`);
  },

  camelCaseToSnakeCase(variable) {
    // convert key from camelCase to snake_case
    if (!variable) {
      return variable;
    }

    return variable.replace(/([A-Z])/g, ($1) => `_${$1.toLowerCase()}`);
  },

  // Converts regular language to camelCase
  // 'VACOLS - 123, User' becomes 'vacolsUser'
  convertToCamelCase(phrase = '') {
    // Code courtesy of Stack Overflow, Question 2970525
    return phrase.toLowerCase().
      replace(/[^a-zA-Z ]/g, '').
      replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, (match, index) => {
        if (Number(match) === 0) {
          return '';
        }

        return index === 0 ? match.toLowerCase() : match.toUpperCase();
      });
  },

  leftPad(string, width, padding = '0') {
    let padded = '';

    for (let i = 0; i < width; i++) {
      padded += padding;
    }

    return (padded + string).slice(-width);
  },

  titleCase(string) {
    return _(string).
      words().
      map(_.capitalize).
      join(' ');
  },

  // https://coderwall.com/p/iprsng/convert-snake-case-to-camelcase
  snakeCaseToCamelCase(variable) {
    // convert key from camelCase to snake_case
    return variable.replace(/(_\w)/g, (found) => found[1].toUpperCase());
  },
  // convert snake_case to Capitalized Words
  snakeCaseToCapitalized(variable) {
    return variable.replace(/_/g, ' ').
      split(' ').
      map((word) => {
        return word[0].toUpperCase() + word.substr(1);
      }).
      join(' ');
  },
  html5CompliantId(str) {
    return str.replace(/[^A-Za-z0-9-]/g, '-').replace(/-+/g, '-');
  },

  // convert (Capitalized) Words to lowercase, snake_case, remove punctuation
  parameterize(str) {
    return str.toLowerCase().replace(/ /g, '_').replace(/,/g, '');
  }
};

export default StringUtil;
