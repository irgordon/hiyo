# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Performance
- Optimized prompt formatting in `MLXProvider` by replacing string concatenation loop with array joining, reducing complexity from O(n²) to O(n).
