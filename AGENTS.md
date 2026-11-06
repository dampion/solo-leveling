# Repository Guidelines

## Project Status

This directory is currently an empty project workspace: no application code, build configuration, tests, or Git history is present. Update this guide as the project gains concrete tooling and conventions. Do not assume a language, framework, or package manager until configuration files establish one.

## Project Structure & Module Organization

When adding the initial implementation, establish a simple layout appropriate to the chosen framework. Suggested locations are `src/` for application code, `tests/` for automated tests, `assets/` for static resources, and `docs/` for supporting documentation. Prefer framework-standard directories when they differ. Group related code by feature and keep generated output separate from maintained source files.

## Build, Test, and Development Commands

No build, test, or local development commands are configured yet. When introducing tooling, document exact setup, run, test, lint, and production build commands in `README.md`. Declare dependencies and required runtime versions in the appropriate project configuration; commit a dependency lockfile when supported. Verify documented commands from a clean checkout before submitting changes.

## Coding Style & Naming Conventions

Use the selected language's standard formatter and linter, and commit their configuration. Match existing file-local conventions once code exists. Use descriptive names, consistent indentation, and small modules with clear responsibilities. Avoid introducing competing formatting tools or unrelated formatting changes.

## Testing Guidelines

No test framework or coverage threshold has been established. Introduce a framework suited to the implementation and document how to run it. Name tests after the behavior they verify, following the framework's discovery conventions. Cover new behavior and relevant failure cases; include regression tests for bug fixes.

## Commit & Pull Request Guidelines

There is no Git history from which to infer commit conventions. Once Git is initialized, use concise, imperative subjects such as `Add initial project configuration`. Keep commits focused. Pull requests should explain the purpose, summarize behavior changes, link relevant issues, and state validation performed. Include screenshots for visual changes and explicitly note any checks that could not run.

## Security & Configuration

Keep credentials and local environment files out of version control. Provide placeholder values in an example configuration file and document required settings. Add generated artifacts and local caches to `.gitignore` when introducing tooling.
