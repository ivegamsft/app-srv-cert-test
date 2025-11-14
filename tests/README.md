# Tests

This folder contains all the test cases for the project. Tests ensure that the application and infrastructure are functioning as expected.

## Instructions

1. **Run Local Tests**:
   - Use the `test-local.ps1` script to execute local tests.
   - Command: `pwsh ./test-local.ps1`

2. **Run GitHub Workflow Tests**:
   - Use the `test-github-workflow.ps1` script to test GitHub Actions workflows.
   - Command: `pwsh ./test-github-workflow.ps1`

3. **Add New Tests**:
   - Place new test scripts or files in this folder.
   - Follow the naming convention: `test-<feature>.ps1` or `test-<feature>.js`.

4. **Test Results**:
   - Test results are logged in `TEST_RESULTS.md` at the root of the project.

## Notes
- Ensure all dependencies are installed before running tests.
- Refer to `QUICKSTART.md` for initial setup instructions.