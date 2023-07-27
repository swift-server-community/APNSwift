# Updating code/Release workflow 

APNSwift follows a standard open source release process

## Issue and Pull Request Management

The primary objective of managing Issues and Pull Requests (PRs) is to enable easy reference to them in the future and to ensure a clear record of when specific issues were addressed in a release.

- **Creating GitHub Issues and Linking PRs:** Every significant task should have an associated GitHub issue, and when a PR resolves an issue, it should be linked using GitHub's "resolves #1234" mechanism or another clear indication of the associated issue.

- **Closing Issues and PRs:** When a PR gets merged, the related issue is automatically closed, and the issue is assigned to the milestone corresponding to the release in which the change will be included.

- **Handling PRs without Associated Issues:** In cases where a pull request is made directly without an associated issue, it should be linked to the relevant milestone for the release. However, it's essential not to assign both an issue and a pull request related to the same task to the same milestone, as this could lead to confusion regarding duplicated issue resolutions.

## Release Process

When preparing for a new release, APNSWift will follow these steps. Let's use version `1.2.3` as an example:

1. Check all outstanding PRs, and if any can be merged for the current release (`1.2.3`), consider doing so.

2. Ensure that all recently closed PRs or issues are appropriately assigned to the milestone (`1.2.3`), if not already done.

3. Ensure all documentation is up to date

4. Create a new milestone for the next release, e.g., `1.2.4` or `1.3.0`, and move any remaining issues to it. This way, these tasks are carried over to the "next" release and can be easily located and prioritized.

5. Close the current milestone (`1.2.3`).

6. Finally, go to the GitHub releases page and [draft a new release](https://github.com/apple/swift-metrics/releases/new) with the details of the release version (`1.2.3` in this case) and any relevant release notes or changes. Be sure to include and create the new tag `1.2.3`.

