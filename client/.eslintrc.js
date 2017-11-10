module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es6: true,
    mocha: true,
    node: true
  },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:import/errors',
    'plugin:import/warnings'
  ],
  settings: {
    'import/resolver': {
      node: {
        extensions: [
          '.js',
          '.jsx'
        ]
      }
    }
  },
  parser: 'babel-eslint',
  parserOptions: {
    ecmaFeatures: {
      experimentalObjectRestSpread: true,
      jsx: true
    },
    sourceType: 'module'
  },
  plugins: [
    'react',
    'import',
    'mocha'
  ],
  rules: {
    'accessor-pairs': 'warn',
    'array-bracket-spacing': 'warn',
    'array-callback-return': 'warn',
    'arrow-parens': 'warn',
    'arrow-spacing': 'warn',
    'block-spacing': 'warn',
    'brace-style': 'warn',
    camelcase: ['warn', { properties: 'never' }],
    'class-methods-use-this': ['warn', {
      exceptMethods: [
        'render',
        'getInitialState',
        'getDefaultProps',
        'getChildContext',
        'componentWillMount',
        'componentDidMount',
        'componentWillReceiveProps',
        'shouldComponentUpdate',
        'componentWillUpdate',
        'componentDidUpdate',
        'componentWillUnmount'
      ]
    }],
    'comma-dangle': 'warn',
    'comma-spacing': 'warn',
    'comma-style': 'warn',
    'computed-property-spacing': 'warn',
    curly: 'warn',
    'default-case': 'warn',
    'dot-location': 'warn',
    'dot-notation': 'warn',
    'eol-last': 'warn',
    eqeqeq: 'warn',
    'func-call-spacing': 'warn',
    'func-name-matching': 'warn',
    'func-style': 'warn',
    'generator-star-spacing': 'warn',
    'global-require': 'warn',
    'guard-for-in': 'warn',
    'handle-callback-err': 'warn',
    'id-blacklist': 'warn',
    'id-length': ['warn', { exceptions: ['i', '_', 'x', 'y'] }],
    'id-match': 'warn',
    indent: ['warn', 2],
    'import/extensions': 1,
    // This rule will catch some cases that we don't care about.
    'import/no-named-as-default': 0,
    'import/no-named-as-default-member': 0,
    'import/prefer-default-export': 1,
    // This rule will catch some cases that we don't care about.
    'react/display-name': 0,
    'react/jsx-boolean-value': 1,
    // This rule is too aggressive. It will catch an array of JSX elements, but just because
    // we have an array of elements doesn't mean we're going to put them into the DOM that way.
    // We don't always need to set a key.
    'react/jsx-key': 0,
    'react/jsx-tag-spacing': 1,
    'react/jsx-uses-react': 'warn',
    'react/jsx-uses-vars': 'warn',
    // We have so many places where we have missing PropTypes that it's not worth it to fix this now.
    'react/prop-types': 0,
    // This rule is largely to prevent syntax errors that feel fairly easy to catch, 
    // and it makes our code less readable.
    'react/no-unescaped-entities': 0,
    'react/no-typos': 1,
    'react/self-closing-comp': [1, {
      component: true,
      html: false
    }],
    'jsx-quotes': 'warn',
    'key-spacing': 'warn',
    'keyword-spacing': 'warn',
    'line-comment-position': 'warn',
    'linebreak-style': ['warn', 'unix'],
    'lines-around-comment': 'warn',
    'lines-around-directive': 'warn',
    'max-depth': 'warn',
    'max-len': ['warn', 120],
    'max-lines': [
      'warn',
      {
        max: 400,
        skipComments: true,
        skipBlankLines: true
      }
    ],
    'max-nested-callbacks': 'warn',
    'max-params': ['warn', { max: 5 }],
    'max-statements': [
      'warn',
      {
        max: 12
      }
    ],
    'max-statements-per-line': 'warn',
    'mocha/no-exclusive-tests': 'warn',
    'new-cap': 'warn',
    'new-parens': 'warn',
    'newline-after-var': 'warn',
    'newline-before-return': 'warn',
    'newline-per-chained-call': 'warn',
    'no-alert': 'warn',
    'no-array-constructor': 'warn',
    'no-bitwise': 'warn',
    'no-caller': 'error',
    'no-catch-shadow': 'warn',
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-continue': 'warn',
    'no-div-regex': 'warn',
    'no-duplicate-imports': 'warn',
    'no-else-return': 'warn',
    'no-empty-function': 'warn',
    'no-eq-null': 'warn',
    'no-eval': 'error',
    'no-extend-native': 'error',
    'no-extra-bind': 'warn',
    'no-extra-label': 'warn',
    'no-extra-parens': ['warn', 'functions'],
    'no-floating-decimal': 'warn',
    'no-implicit-coercion': 'warn',
    'no-implicit-globals': 'warn',
    'no-implied-eval': 'error',
    'no-iterator': 'error',
    'no-label-var': 'error',
    'no-labels': 'error',
    'no-lone-blocks': 'warn',
    'no-lonely-if': 'warn',
    'no-loop-func': 'warn',
    'no-mixed-operators': 'warn',
    'no-mixed-requires': 'warn',
    'no-multi-spaces': 'warn',
    'no-multi-str': 'error',
    'no-multiple-empty-lines': ['warn', { max: 1 }],
    'no-native-reassign': 'error',
    'no-negated-condition': 'warn',
    'no-unsafe-negation': 'warn',
    'no-nested-ternary': 'warn',
    'no-new': 'warn',
    'no-new-func': 'warn',
    'no-new-object': 'warn',
    'no-new-require': 'warn',
    'no-new-wrappers': 'warn',
    'no-octal-escape': 'warn',
    'no-param-reassign': 'warn',
    'no-path-concat': 'warn',
    'no-plusplus': ['warn', { allowForLoopAfterthoughts: true }],
    'no-process-env': 'warn',
    'no-process-exit': 'warn',
    'no-proto': 'warn',
    'no-prototype-builtins': 'error',
    'no-script-url': 'error',
    'no-self-compare': 'warn',
    'no-sequences': 'warn',
    'no-shadow': 'warn',
    'no-shadow-restricted-names': 'warn',
    'no-tabs': 'warn',
    'no-template-curly-in-string': 'warn',
    'no-throw-literal': 'warn',
    'no-trailing-spaces': 'warn',
    'no-undef-init': 'warn',
    'no-undefined': 'warn',
    'no-underscore-dangle': 'warn',
    'no-unmodified-loop-condition': 'warn',
    'no-unneeded-ternary': 'warn',
    'no-unused-expressions': 'warn',
    'no-use-before-define': 'error',
    'no-useless-call': 'warn',
    'no-useless-computed-key': 'warn',
    'no-useless-concat': 'warn',
    'no-useless-constructor': 'warn',
    'no-useless-escape': 'warn',
    'no-useless-rename': 'warn',
    'no-useless-return': 'warn',
    'no-var': 'warn',
    'no-void': 'warn',
    'no-whitespace-before-property': 'warn',
    'no-with': 'error',
    'object-curly-spacing': [
      'warn',
      'always'
    ],
    'object-property-newline': 'warn',
    'object-shorthand': 'warn',
    'one-var-declaration-per-line': 'warn',
    'operator-assignment': 'warn',
    'operator-linebreak': ['warn', 'after'],
    'prefer-arrow-callback': 'warn',
    'prefer-numeric-literals': 'warn',
    'prefer-rest-params': 'warn',
    'prefer-spread': 'warn',
    'prefer-template': 'warn',
    quotes: ['warn', 'single', { avoidEscape: true }],
    'quote-props': ['warn', 'as-needed'],
    radix: 'warn',
    'rest-spread-spacing': 'warn',
    semi: 'warn',
    'semi-spacing': 'warn',
    'sort-imports': 'off',
    'sort-vars': 'warn',
    'space-before-blocks': 'warn',
    'space-in-parens': [
      'warn',
      'never'
    ],
    'space-infix-ops': 'warn',
    'space-unary-ops': 'warn',
    'spaced-comment': [
      'warn',
      'always'
    ],
    strict: 'error',
    'symbol-description': 'warn',
    'template-curly-spacing': 'warn',
    'unicode-bom': [
      'warn',
      'never'
    ],
    'wrap-regex': 'warn',
    'yield-star-spacing': 'warn',
    yoda: 'warn'
  }
};
