# Contributing

Welcome! This project accepts any kind of contribution, be it code, assets,
documentation, testing or localization. You are expected to follow the guidelines below
for any contribution regardless of size. If you have questions after reading this
document please ask them on Matrix.

In general, before starting to work on anything please make sure to discuss your
change by creating an issue first. Using Matrix is also welcome.

To get your changes merged: fork this repository, create a branch, add your changes and open a
Merge Request here.

## Commits

It is preferred that each commit changes only one part of the repository, although not necessary
if the changes are related to each other.

Your commit messages should be organized like this:
<part(s) of the repository changed (server,client,common)>: <short description of what's changed>

Examples:
- server: Fixed desync issue
- common, client: Fixed small typo, added vsync setting
- docs: Fixed typo

## Contributing code

Make sure that:
- Your code is formatted using `cargo fmt`.
- The project builds fine with both debug and release templates.
- The change is tested, and does not create a regression in related parts of the
project.

## Reporting a bug / requesting a feature

Fill out the related templates in issue tracker. Non-reproducible bugs will have a lower
priority.
