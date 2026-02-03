# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Performance
- Optimized prompt formatting in `MLXProvider` by using efficient string joining.
- Removed unused string accumulation in generation loop, eliminating unnecessary memory allocation and copying.
