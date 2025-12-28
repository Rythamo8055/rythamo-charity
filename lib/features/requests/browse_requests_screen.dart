import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/request_service.dart';
import '../../core/models/item_request_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/request_card.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../discovery/orphanage_detail_screen.dart';

class BrowseRequestsScreen extends StatelessWidget {
  const BrowseRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestService requestService = RequestService();

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("URGENT NEEDS", style: AppTypography.sectionHeader(context)),
                  Text(
                    "Help orphanages with specific items",
                    style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ItemRequest>>(
                stream: requestService.getActiveRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(message: "Finding urgent needs...");
                  }

                  if (snapshot.hasError) {
                    return ErrorStateWidget(
                      message: "Could not load requests",
                      onRetry: () => (context as Element).markNeedsBuild(),
                    );
                  }

                  final requests = snapshot.data ?? [];

                  if (requests.isEmpty) {
                    return const EmptyStateWidget(
                      lottiePath: 'assets/mascot/celebrating.json',
                      message: "All requests fulfilled!",
                      subMessage: "Check back later for new ways to help",
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return RequestCard(
                        request: request,
                        showOrphanageName: true,
                        actionLabel: "I Can Help",
                        onActionPressed: () {
                          // Navigate to orphanage details to make an offer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrphanageDetailScreen(
                                orphanageId: request.orphanageId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
