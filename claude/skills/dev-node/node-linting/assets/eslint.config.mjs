// Canonical ESLint 9 flat config for Node.js / TypeScript projects.
// Drop into the repo root. Pair with .prettierrc (assets/prettierrc.json).
//
// Requires: eslint@^9, typescript-eslint@^8, eslint-plugin-import,
//           eslint-config-prettier.

import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  // Base JS recommended rules.
  js.configs.recommended,

  // TypeScript strict + stylistic with type-aware checking.
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,

  // Import ordering and cycle detection.
  importPlugin.flatConfigs.recommended,
  importPlugin.flatConfigs.typescript,

  // Project-wide settings.
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // Catch missed awaits at PR time.
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',

      // Force `import type` for type-only imports (works with verbatimModuleSyntax).
      '@typescript-eslint/consistent-type-imports': 'error',

      // Force return-type annotations on exported / module-boundary functions.
      '@typescript-eslint/explicit-module-boundary-types': 'error',

      // Switches over discriminated unions must be exhaustive.
      '@typescript-eslint/switch-exhaustiveness-check': 'error',

      // No `any`.
      '@typescript-eslint/no-explicit-any': 'error',

      // Force `===` / `!==`.
      eqeqeq: ['error', 'always'],

      // Always declare immutable bindings.
      'prefer-const': 'error',

      // Import order: stdlib → external → internal, alphabetized, blank line between.
      'import/order': [
        'error',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling'],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
      'import/no-cycle': 'error',
      'import/no-default-export': 'error', // remove if framework requires default exports

      // Naming convention — see node-naming skill.
      '@typescript-eslint/naming-convention': [
        'error',
        { selector: 'default', format: ['camelCase'] },
        { selector: 'variable', format: ['camelCase', 'UPPER_CASE'] },
        { selector: 'parameter', format: ['camelCase'], leadingUnderscore: 'allow' },
        { selector: 'typeLike', format: ['PascalCase'] },
        { selector: 'enumMember', format: ['PascalCase'] },
        { selector: 'objectLiteralProperty', format: null },
      ],
    },
  },

  // Tests can be looser.
  {
    files: ['**/*.test.ts', '**/*.spec.ts', '**/test/**/*.ts'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      'import/no-default-export': 'off',
    },
  },

  // Config files (this file, vite.config.ts, etc.) may default-export.
  {
    files: ['*.config.{ts,mts,mjs,cts,cjs,js}', 'vite.config.ts', 'vitest.config.ts'],
    rules: {
      'import/no-default-export': 'off',
    },
  },

  // Prettier last — disables stylistic rules that conflict with the formatter.
  prettierConfig,
);
