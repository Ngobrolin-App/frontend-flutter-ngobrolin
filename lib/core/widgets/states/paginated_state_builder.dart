import 'package:flutter/material.dart';
import 'empty_state.dart';

class PaginatedStateBuilder extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function() onRefresh;

  final Widget child;

  final bool isEmpty;
  final String emptyMessage;
  final String? emptySubtitle;
  final bool showEmptyButton;
  final String? emptyButtonText;
  final VoidCallback? onEmptyButtonPressed;

  const PaginatedStateBuilder({
    super.key,
    required this.isLoading,
    required this.onRefresh,

    required this.child,

    required this.isEmpty,
    required this.emptyMessage,
    this.emptySubtitle,
    this.showEmptyButton = false,
    this.emptyButtonText,
    this.onEmptyButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isLoading && isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: EmptyState(
                  title: emptyMessage,
                  subtitle: emptySubtitle, // Terapkan di sini
                  showButton: showEmptyButton,
                  buttonText: emptyButtonText,
                  onButtonPressed: onEmptyButtonPressed,
                ),
              ),
            );
          }
          return child;
        },
      ),
    );
  }
}
