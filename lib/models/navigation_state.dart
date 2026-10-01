/// Enumeration of live navigation session execution states (Phase 4).
enum NavigationState {
  routePreview,
  navigationStarting,
  navigating,
  rerouting,
  arrived,
  navigationFinished,
  navigationError,
}

extension NavigationStateX on NavigationState {
  String get displayLabel {
    switch (this) {
      case NavigationState.routePreview:
        return 'Route Preview';
      case NavigationState.navigationStarting:
        return 'Starting Navigation...';
      case NavigationState.navigating:
        return 'Navigating';
      case NavigationState.rerouting:
        return 'Recalculating safety-aware route...';
      case NavigationState.arrived:
        return 'Arrived at destination!';
      case NavigationState.navigationFinished:
        return 'Trip Completed';
      case NavigationState.navigationError:
        return 'Navigation Error';
    }
  }
}
